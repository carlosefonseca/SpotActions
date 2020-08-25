//
//  FakeSpotifyAuthManager.swift
//

import Foundation
import Combine
import CEFSpotifyCore

public class FakeSpotifyAuthManager: SpotifyAuthManager {

    public init(initialState: AuthState = .notLoggedIn) {
        state = initialState
    }

    public func login() {
        state = .loggedIn(token: TokenResponse())
    }

    public func logout() {
        state = .notLoggedIn
    }

    public func refreshToken(completion: @escaping (Error?) -> Void) {}

    @Published public var state: AuthState

    public var statePublished: Published<AuthState> { _state }
    public var statePublisher: Published<AuthState>.Publisher { $state }
}
