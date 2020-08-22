//
//  SpotifyGateway.swift
//

import Foundation
import Combine

public protocol WebApiError: Error {}

public struct SpotifyWebApiError: Error, Decodable {
    let error: SpotifyRegularError
}

public struct SpotifyRegularError: Decodable {
    let status: Int
    let message: String
}

public enum SpotifyRequestError: WebApiError, LocalizedError {
    case requestError(error: Error?)
    case networkError(error: Error)
    case httpError(error: ResponseType, data: Data?)
    case parseError(error: Error)
    case apiError(error: ResponseType, data: SpotifyRegularError)
    case noLogin
}

public struct User: Codable {
    public var country: String?
    public var display_name: String?
    public var email: String?
    //   public var external_urls : [String:String]?
    //   public var followers : String?
    public var href: String?
    public var id: String?
    //   public var images : String?
    public var product: String?
    public var type: String?
    public var uri: String?
}

public protocol URLRequestable {
    var urlRequest: URLRequest { get }
}

public protocol SpotifyWebApiGateway {
    func user(callback: @escaping (Result<User, SpotifyRequestError>) -> Void)
}

public class SASpotifyWebApiGateway: SpotifyWebApiGateway {

    let baseURL: URL
    let requestManager: RequestManager

    public init(baseURL: URL, requestManager: RequestManager) {
        self.baseURL = baseURL
        self.requestManager = requestManager
    }

    public func user(callback: @escaping (Result<User, SpotifyRequestError>) -> Void) {
        let request = UserRequest(baseURL: baseURL)
        requestManager.execute(request: request) { (result: Result<User, SpotifyRequestError>) in
            callback(result)
        }
    }
}

public struct UserRequest: URLRequestable {

    let url: URL!

    init(baseURL: URL) {
        url = URL(string: "/v1/me", relativeTo: baseURL)
    }

    public var urlRequest: URLRequest {
        URLRequest(url: url)
    }
}

public protocol RequestManager {
    func execute<T>(request: URLRequestable, completion: @escaping (Result<T, SpotifyRequestError>) -> Void) where T: Decodable
//    func execute(request: URLRequestable, completion: @escaping (Error?) -> Void)
//    func execute(request: URLRequest, completion: @escaping (Result<(HTTPURLResponse, Data?)>) -> Void)
}

public class AuthenticatedSpotifyRequestManager: RequestManager {

    let jsonDecoder: JSONDecoder
    let urlSession = URLSession.shared

    let auth: SpotifyAuthManager

    var token: TokenResponse?

    var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager) {
        self.auth = auth
        jsonDecoder = JSONDecoder()

        self.auth.statePublisher.sink { authState in
            switch authState {
            case .loggedIn(let token):
                self.token = token
            default:
                self.token = nil
            }
        }.store(in: &bag)
    }

    public func execute<T>(request: URLRequestable, completion: @escaping (Result<T, SpotifyRequestError>) -> Void) where T: Decodable {

        guard let token = token, let accessToken = token.access_token else {
            completion(.failure(SpotifyRequestError.noLogin))
            return
        }

        var urlRequest = request.urlRequest

        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        exec(urlRequest: urlRequest) { [self] result in
            switch result {
            case .success(let data):
                do {
                    let entity = try self.jsonDecoder.decode(T.self, from: data)
                    completion(.success(entity))
                } catch {
                    completion(.failure(SpotifyRequestError.parseError(error: error)))
                }
                return
            case .failure(let error):
                switch error {
                case .apiError(let innerError, _), .httpError(let innerError, _):
                    switch innerError {
                    case .unauthorized:
                        auth.refreshToken { _ in exec(urlRequest: urlRequest) { result in
                            switch result {
                            case .success(let data):
                                do {
                                    let entity = try self.jsonDecoder.decode(T.self, from: data)
                                    completion(.success(entity))
                                } catch {
                                    completion(.failure(SpotifyRequestError.parseError(error: error)))
                                }
                                return
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                        }
                    default:
                        completion(.failure(error))
                    }
                default:
                    completion(.failure(error))
                }
            }
        }
    }

    func exec(urlRequest: URLRequest, completion: @escaping (Result<Data, SpotifyRequestError>) -> Void) {
        urlSession.dataTask(with: urlRequest) { data, response, error in
            guard error == nil else {
                completion(.failure(SpotifyRequestError.requestError(error: error)))
                return
            }

            // Check if we have a `HTTPURLResponse`
            guard let httpUrlResponse = response as? HTTPURLResponse else {
                completion(.failure(SpotifyRequestError.requestError(error: error)))
                return
            }


            // Check if response is success or a known error
            switch httpUrlResponse.type {
            case .success:

                guard let data = data else {
                    completion(.failure(SpotifyRequestError.httpError(error: httpUrlResponse.type, data: nil)))
                    return
                }

                completion(.success(data))
                return

            case .unauthorized, .forbidden, .error:

                guard let responseData = data else {
                    completion(.failure(SpotifyRequestError.httpError(error: httpUrlResponse.type, data: nil)))
                    return
                }

                guard let apiError = try? self.jsonDecoder.decode(SpotifyWebApiError.self, from: responseData) else {
                    completion(.failure(SpotifyRequestError.httpError(error: httpUrlResponse.type, data: responseData)))
                    return
                }

                completion(.failure(SpotifyRequestError.apiError(error: httpUrlResponse.type, data: apiError.error)))

            case .other:
                completion(.failure(SpotifyRequestError.httpError(error: httpUrlResponse.type, data: data)))
            }
        }.resume()
    }
}


extension NSError {
    func isNetworkConnectionError() -> Bool {
        let networkErrors = [NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet]

        return domain == NSURLErrorDomain && networkErrors.contains(code)
    }
}

extension HTTPURLResponse {

    var isSuccess: Bool {
        return (200...299).contains(statusCode)
    }

    var isUnauthorized: Bool {
        return statusCode == 401
    }

    var isNotFound: Bool {
        return statusCode == 404
    }

    var isForbidden: Bool {
        return statusCode == 403
    }

    var isServerError: Bool {
        return (500..<600).contains(statusCode)
    }

    var type: ResponseType {
        if isSuccess { return .success }
        if isUnauthorized { return .unauthorized }
        if isForbidden { return .forbidden }
        if isServerError { return .error }
        return .other
    }
}

public enum ResponseType {
    case success
    case unauthorized
    case forbidden
    case error
    case other
}
