//
//  SpotActionsApp.swift
//

import SwiftUI
import Intents
import CEFSpotifyCore

struct Gateways {
    let userProfile: SpotifyUserProfileGateway
    let playlists: SpotifyPlaylistsGateway

    init(baseURL: URL, requestManager: RequestManager) {
        userProfile = SpotifyUserProfileGatewayImplementation(baseURL: baseURL, requestManager: requestManager)
        playlists = SpotifyPlaylistsGatewayImplementation(baseURL: baseURL, requestManager: requestManager)
    }
}

struct Dependencies {
    var keychain: CredentialStore
    var auth: SpotifyAuthManager
    var spotifyRequestManager: RequestManager
    var requester: URLRequester

    var gateways: Gateways

    var userManager: UserManager
    var playlistsManager: PlaylistsManager

    init() {
        keychain = Keychain()
        requester = UrlSessionRequester()
        auth = SpotifyAuthManagerImplementation(webAuthManager: WebAuthManager(), credentialStore: keychain, requester: requester)
        spotifyRequestManager = AuthenticatedSpotifyRequestManager(auth: auth, requester: requester)
        gateways = Gateways(baseURL: URL(string: "https://api.spotify.com")!, requestManager: spotifyRequestManager)

        userManager = UserManagerImplementation(auth: auth, gateway: gateways.userProfile)
        playlistsManager = PlaylistsManagerImplementation(auth: auth, gateway: gateways.playlists)
    }
}

@main
struct SpotActionsApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var dependencies: Dependencies { appDelegate.dependencies }

    var body: some Scene {
        WindowGroup {
            ContentView(presenter: Presenter(auth: dependencies.auth,
                                             userManager: dependencies.userManager,
                                             playlistManager: dependencies.playlistsManager))
        }
    }
}

// @UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var dependencies = Dependencies()

    lazy var userProfileHandler: GetUserProfileHandler = { GetUserProfileHandler(auth: dependencies.auth, userManager: dependencies.userManager) }()
    lazy var userPlaylistHandler: GetUserPlaylistsHandler = { GetUserPlaylistsHandler(auth: dependencies.auth, userManager: dependencies.userManager, playlistsManager: dependencies.playlistsManager) }()
    lazy var playlistTracksHandler: GetPlaylistTracksHandler = { GetPlaylistTracksHandler(auth: dependencies.auth, userManager: dependencies.userManager, playlistsManager: dependencies.playlistsManager) }()

    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        switch intent {
        case is GetUserProfileIntent:
            return userProfileHandler
        case is GetUserPlaylistsIntent:
            return userPlaylistHandler
        case is GetPlaylistTracksIntent:
            return playlistTracksHandler
        default:
            fatalError("No handler for this intent")
        }
    }
}
