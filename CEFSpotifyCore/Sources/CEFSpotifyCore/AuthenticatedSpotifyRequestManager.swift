//
//  AuthenticatedSpotifyRequestManager.swift
//

import Foundation
import Combine

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
                print(error)
                switch error {
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

            case .unauthorized:
                completion(.failure(.unauthorized(error: httpUrlResponse.type)))
                return

            case .forbidden, .error:
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

public enum ResponseType: String, RawRepresentable, CustomStringConvertible {
    case success
    case unauthorized
    case forbidden
    case error
    case other

    public var description: String { rawValue }
}
