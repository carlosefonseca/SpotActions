//
//  AuthenticatedSpotifyRequestManager.swift
//

import Foundation
import Combine

public class AuthenticatedSpotifyRequestManager: RequestManager {

    let jsonDecoder = JSONDecoder()
    let urlSession = URLSession.shared // TODO: REMOVE

    let auth: SpotifyAuthManager
    let requester: URLRequester

    var token: TokenResponse?

    var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, requester: URLRequester) {
        self.auth = auth
        self.requester = requester

        self.auth.statePublisher.sink { authState in
            switch authState {
            case .loggedIn(let token):
                self.token = token
            default:
                self.token = nil
            }
        }.store(in: &bag)
    }

    func applyAccessTokenToRequest(urlRequest: URLRequest, token: TokenResponse) throws -> URLRequest {
        guard let accessToken = token.access_token else {
            throw SpotifyRequestError.noLogin
        }

        var urlRequest = urlRequest

        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }

    public func execute<T>(request: URLRequestable) -> AnyPublisher<T, Error> where T: Codable {
        return execute(urlRequest: request.urlRequest)
    }

    public func execute<T>(urlRequest: URLRequest) -> AnyPublisher<T, Error> where T: Codable {
        return auth.statePublisher.first()
            .tryMap { (auth: AuthState) throws -> URLRequest in
                guard case .loggedIn(let tokenResponse) = auth else {
                    throw SpotifyRequestError.noLogin
                }
                return try self.applyAccessTokenToRequest(urlRequest: urlRequest, token: tokenResponse)

            }.flatMap { urlRequest -> AnyPublisher<T, Error> in

                self.requester.request(urlRequest: urlRequest)
                    .print("SpotifyRequestManager")
                    .catch { (error: UrlRequesterError) -> AnyPublisher<T, Error> in
                        if case UrlRequesterError.apiError(let response, let data) = error {
                            print(String(data: data, encoding: .utf8) ?? "noData")
                            if case .unauthorized = response.type {
                                return self.refreshRetry(urlRequest: urlRequest)
                            }
                        }
                        return Fail<T, Error>(error: error).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()

            }.eraseToAnyPublisher()
    }

    func refreshRetry<T>(urlRequest: URLRequest) -> AnyPublisher<T, Error> where T: Codable {
        auth.refreshToken()
            .tryMap { (token: TokenResponse) -> URLRequest in
                try self.applyAccessTokenToRequest(urlRequest: urlRequest, token: token)
            }.eraseToAnyPublisher()
            .flatMap { (urlRequest: URLRequest) -> AnyPublisher<T, Error> in
                self.requester.request(urlRequest: urlRequest)
                    .mapError { (error: UrlRequesterError) -> Error in error as Error }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}
