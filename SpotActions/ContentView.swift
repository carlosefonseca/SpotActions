//
//  ContentView.swift
//

import SwiftUI
import AuthenticationServices
import CEFSpotifyCore
import Combine

class Presenter: ObservableObject {

    var auth: SpotifyAuthManager

    @Published var isAuthenticated = false

    var sub : AnyCancellable?

    init(auth: SpotifyAuthManager) {
        self.auth = auth

        sub = self.auth.statePublisher
            .receive(on: RunLoop.main)
            .sink { authState in
            if case .notLoggedIn = authState {
                self.isAuthenticated = false
            } else {
                self.isAuthenticated = true
            }
        }
    }
}

struct ContentView: View {

    @ObservedObject var presenter: Presenter

    @ViewBuilder
    var body: some View {
        VStack {
            Text("Hello, world!").padding()
            if presenter.isAuthenticated {
                Text("Ola").padding()
                Button("Logout", action: { presenter.auth.logout() })
            } else {
                Button("Login", action: { presenter.auth.login() })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(presenter: Presenter(auth: FakeSpotifyAuthManager()))
    }
}

class FakeSpotifyAuthManager: SpotifyAuthManager {
    init(initialState: AuthState = .notLoggedIn) {
        state = initialState
    }

    func login() {
        state = .loggedIn(token: TokenResponse())
    }

    func logout() {
        state = .notLoggedIn
    }

    @Published var state: AuthState

    var statePublished: Published<AuthState> { _state }
    var statePublisher: Published<AuthState>.Publisher { $state }
}
