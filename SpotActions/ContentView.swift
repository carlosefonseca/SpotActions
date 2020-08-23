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

    var userManager: UserManager

    @Published var user: UserJSON?

    var bag = Set<AnyCancellable>()

    @Published var error: Error?

    init(auth: SpotifyAuthManager, userManager: UserManager) {
        self.auth = auth
        self.userManager = userManager

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

        self.userManager.userPublisher
            .receive(on: RunLoop.main)
            .sink { self.user = $0 }
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
                    Text("Error: \(error.localizedDescription)").foregroundColor(.red)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(presenter: Presenter(auth: FakeSpotifyAuthManager(), userManager: FakeUserManager()))
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

    func refreshToken(completion: @escaping (Error?) -> Void) {}

    @Published var state: AuthState

    var statePublished: Published<AuthState> { _state }
    var statePublisher: Published<AuthState>.Publisher { $state }
}

class FakeUserManager: UserManager {
    @Published var user: UserJSON?

    var userPublished: Published<UserJSON?> { _user }

    var userPublisher: Published<UserJSON?>.Publisher { $user }

    var fakeUser: UserJSON?

    func getUser(completion: @escaping (Result<UserJSON, SpotifyRequestError>) -> Void) {
        user = fakeUser
        completion(Result.success(fakeUser!))
    }
}
