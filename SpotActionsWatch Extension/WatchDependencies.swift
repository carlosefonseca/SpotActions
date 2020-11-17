//
// WatchDependencies.swift
//

import UIKit
import Combine
import SwiftUI
import Intents
import CEFSpotifyCore
import WatchConnectivity
import CEFSpotifyDoubles

struct WatchDependencies: Dependencies {
    var keychain: CredentialStore

    var auth: SpotifyAuthManager

    var spotifyRequestManager: RequestManager

    var requester: URLRequester

    var gateways: Gateways

    var userManager: UserManager

    var playlistsManager: PlaylistsManager

    var playerManager: PlayerManager

    var trackFilterService: TrackFilterService

    var trackMixerService: TrackMixerService

    var systemPublishers: SystemPublishers

    init() {
        keychain = Keychain()
        requester = UrlSessionRequester()
        auth = SpotifyAuthManagerImplementation(webAuthManager: NoCanDoWebAuth(), credentialStore: keychain, requester: requester)
        spotifyRequestManager = AuthenticatedSpotifyRequestManager(auth: auth, requester: requester)
        gateways = Gateways(baseURL: URL(string: "https://api.spotify.com")!, requestManager: spotifyRequestManager)

        userManager = UserManagerImplementation(auth: auth, gateway: gateways.userProfile)
        playlistsManager = PlaylistsManagerImplementation(auth: auth, gateway: gateways.playlists)
        playerManager = PlayerManagerImplementation(gateway: gateways.player)

        trackFilterService = TrackFilterServiceImplementation(playlistsManager: playlistsManager)
        trackMixerService = TrackMixerServiceImplementation(playlistsManager: playlistsManager)

        systemPublishers = WatchSystemPublishers()
    }
}

public class MockSpotifyAuthManager: SpotifyAuthManager {

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

    public var statePublisher: AnyPublisher<AuthState, Never> { $state.eraseToAnyPublisher() }
}

struct NoCanDoWebAuth: WebAuth {

    func executeLogin(url: URL, callbackURLScheme: String, callback: @escaping (Result<URL, Error>) -> Void) {
        callback(.failure("Please login on the iOS app"))
    }
}
