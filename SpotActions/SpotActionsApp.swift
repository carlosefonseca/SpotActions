//
//  SpotActionsApp.swift
//

import SwiftUI
import CEFSpotifyCore

struct Gateways {
    let userProfile: SpotifyUserProfileGateway

    init(baseURL: URL, requestManager: RequestManager) {
        userProfile = SpotifyUserProfileGatewayImplementation(baseURL: baseURL, requestManager: requestManager)
    }
}

struct Dependencies {
    var keychain: CredentialStore
    var auth: SpotifyAuthManager
    var spotifyRequestManager: RequestManager

    var userManager: UserManager

    var gateways: Gateways

    init() {
        keychain = Keychain()
        auth = SpotifyAuthManagerImplementation(webAuthManager: WebAuthManager(), credentialStore: keychain)
        spotifyRequestManager = AuthenticatedSpotifyRequestManager(auth: auth)
        gateways = Gateways(baseURL: URL(string: "https://api.spotify.com")!, requestManager: spotifyRequestManager)

        userManager = UserManagerImplementation(auth: auth, gateway: gateways.userProfile)
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
