//
//  SpotActionsApp.swift
//

import SwiftUI
import CEFSpotifyCore

struct Dependencies {
    var keychain:CredentialStore
    var auth : SpotifyAuthManager

    init() {
        keychain = Keychain()
        auth = SpotifyAuthManagerImplementation(webAuthManager:WebAuthManager(), credentialStore: keychain)
    }

}


@main
struct SpotActionsApp: App {

    var dependencies = Dependencies()

    var body: some Scene {
        WindowGroup {
            ContentView(presenter: Presenter(auth: dependencies.auth))
        }
    }
}
