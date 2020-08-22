//
//  SpotActionsApp.swift
//

import SwiftUI
import CEFSpotifyCore

struct Dependencies {
    var keychain: CredentialStore
    var auth: SpotifyAuthManager
    var spotifyRequestManager: RequestManager
    var spotifyGateway: SpotifyWebApiGateway
    var userManager : UserManager

    init() {
        keychain = Keychain()
        auth = SpotifyAuthManagerImplementation(webAuthManager: WebAuthManager(), credentialStore: keychain)
        spotifyRequestManager = AuthenticatedSpotifyRequestManager(auth: auth)
        spotifyGateway = SASpotifyWebApiGateway(baseURL: URL(string: "https://api.spotify.com")!, requestManager: spotifyRequestManager)
        userManager = UserManagerImplementation(auth: auth, gateway: spotifyGateway)
    }
}

@main
struct SpotActionsApp: App {

    var dependencies = Dependencies()

    var body: some Scene {
        WindowGroup {
            ContentView(presenter: Presenter(auth: dependencies.auth, userManager: dependencies.userManager))
        }
    }
}
