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

    var gateways: Gateways

    var userManager: UserManager
    var playlistsManager: PlaylistsManager

    init() {
        keychain = Keychain()
        auth = SpotifyAuthManagerImplementation(webAuthManager: WebAuthManager(), credentialStore: keychain)
        spotifyRequestManager = AuthenticatedSpotifyRequestManager(auth: auth)
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

    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        switch intent {
        case is GetUserProfileIntent:
            return GetUserProfileHandler(auth: dependencies.auth, userManager: dependencies.userManager)
        case is GetUserPlaylistsIntent:
            return GetUserPlaylistsHandler(auth: dependencies.auth, userManager: dependencies.userManager, playlistsManager: dependencies.playlistsManager)
        default:
            fatalError("No handler for this intent")
        }
    }
}
