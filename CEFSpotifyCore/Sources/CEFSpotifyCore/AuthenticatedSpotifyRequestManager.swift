//
//  AuthenticatedSpotifyRequestManager.swift
//

import Foundation
import Combine

public class AuthenticatedSpotifyRequestManager: RequestManager {

    let jsonDecoder: JSONDecoder

    let auth: SpotifyAuthManager
    let requester: URLRequester

    var token: TokenResponse?

    var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, requester: URLRequester) {
        self.auth = auth
        self.requester = requester
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

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
        guard let accessToken = token.accessToken else {
            throw SpotifyRequestError.noLogin
        }

        var urlRequest = urlRequest

        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }

    public func execute(request: URLRequestable) -> AnyPublisher<Data, Error> {
        return execute(urlRequest: request.urlRequest)
    }

    public func execute(urlRequest: URLRequest) -> AnyPublisher<Data, Error> {
        return auth.statePublisher.first()
            .tryMap { (auth: AuthState) throws -> URLRequest in
                guard case .loggedIn(let tokenResponse) = auth else {
                    throw SpotifyRequestError.noLogin
                }
                return try self.applyAccessTokenToRequest(urlRequest: urlRequest, token: tokenResponse)
            }
            .print("SpotifyRequestManager")
            .flatMap { urlRequest in self.runTheRequest(urlRequest, canRetry: true)
            }.eraseToAnyPublisher()
    }

    func refreshRetry(urlRequest: URLRequest) -> AnyPublisher<Data, Error> {
        auth.refreshToken()
            .tryMap { (token: TokenResponse) -> URLRequest in
                try self.applyAccessTokenToRequest(urlRequest: urlRequest, token: token)
            }.eraseToAnyPublisher()
            .flatMap { (urlRequest: URLRequest) -> AnyPublisher<Data, Error> in
                self.runTheRequest(urlRequest, canRetry: false)
            }.eraseToAnyPublisher()
    }

    fileprivate func runTheRequest(_ urlRequest: URLRequest, canRetry: Bool) -> AnyPublisher<Data, Error> {
        return requester.request(urlRequest: urlRequest)
            .catch { (error: UrlRequesterError) -> AnyPublisher<Data, Error> in
                self.handleRequest(error: error, urlRequestToRetry: canRetry ? urlRequest : nil)
            }
            .eraseToAnyPublisher()
    }

    fileprivate func handleRequest(error: UrlRequesterError, urlRequestToRetry urlRequest: URLRequest? = nil) -> AnyPublisher<Data, Error> {
        if let urlRequest = urlRequest {
            if case UrlRequesterError.apiError(let response, let data) = error {
                print(String(data: data, encoding: .utf8) ?? "noData")
                if case .unauthorized = response.type {
                    return refreshRetry(urlRequest: urlRequest)
                }
            }
        }
        return Fail<Data, Error>(error: error).eraseToAnyPublisher()
    }
}
