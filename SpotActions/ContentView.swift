//
//  ContentView.swift
//

import SwiftUI
import AuthenticationServices
import CEFSpotifyCore
import Combine
import CEFSpotifyDoubles

class Presenter: ObservableObject {

    var auth: SpotifyAuthManager

    @Published var isAuthenticated = false

    var userManager: UserManager

    @Published var user: UserJSON?

    var bag = Set<AnyCancellable>()

    @Published var error: String?

    var playlistManager: PlaylistsManager

    @Published var playlists: [PlaylistJSON]?

    public init(auth: SpotifyAuthManager, userManager: UserManager, playlistManager: PlaylistsManager) {
        self.auth = auth
        self.userManager = userManager
        self.playlistManager = playlistManager

        self.auth.statePublisher
            .receive(on: RunLoop.main)
            .sink { [self] authState in
                switch authState {
                case .notLoggedIn:
                    isAuthenticated = false
                case .loggedIn:
                    isAuthenticated = true
                case .error(let error):
                    isAuthenticated = false
                    self.error = error
                }
            }.store(in: &bag)

        self.userManager.userPublisher.print("Presenter>userManager.userPublisher")
            .receive(on: RunLoop.main)
            .sink { self.user = $0 }
            .store(in: &bag)

        self.playlistManager.publisher
            .receive(on: RunLoop.main)
            .sink { self.playlists = $0 }
            .store(in: &bag)
    }
}

struct ContentView: View {

    @ObservedObject var presenter: Presenter

    @ViewBuilder
    var body: some View {
        VStack {
            Text("Hello, world!").padding()
            if presenter.isAuthenticated {
                Text("Ola \(presenter.user?.display_name ?? "<?>")").padding()
                Button("Logout", action: { presenter.auth.logout() })
            } else {
                Button("Login", action: { presenter.auth.login() })
                if let error = presenter.error {
                    Text("Error: \(error)").foregroundColor(.red)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(presenter: Presenter(auth: FakeSpotifyAuthManager(),
                                         userManager: FakeUserManager(),
                                         playlistManager: FakePlaylistsManager()))
    }
}
