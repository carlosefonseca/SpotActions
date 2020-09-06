//
//  FakeSpotifyAuthManager.swift
//

import Foundation
import Combine
import CEFSpotifyCore

public class FakeSpotifyAuthManager: SpotifyAuthManager {

    public var refreshTokenResponse: Result<TokenResponse, RefreshTokenError>?

    public init(initialState: AuthState = .notLoggedIn) {
        state = initialState
    }

    public func refreshToken() -> AnyPublisher<TokenResponse, RefreshTokenError> {

        return Deferred {
            Future { promise in
                switch self.refreshTokenResponse {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(error))
                case .none:
                    promise(.failure(RefreshTokenError.other(message: "No Refresh Token Response set!")))
                }
            }
        }.eraseToAnyPublisher()

//        return Just(TokenResponse()).setFailureType(to: RefreshTokenError.self).eraseToAnyPublisher()
    }

    public func login() {
        state = .loggedIn(token: TokenResponse())
    }

    public func logout() {
        state = .notLoggedIn
    }

    @Published public var state: AuthState

    public var statePublisher: Published<AuthState>.Publisher { $state }
}
