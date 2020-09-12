//
//  UserManager.swift
//

import Foundation
import Combine

public protocol UserManager {
    var user: UserJSON? { get }
    var userPublisher: AnyPublisher<UserJSON?, Never> { get }

    func getUser() -> AnyPublisher<UserJSON, Error>
}

public class UserManagerImplementation: UserManager, ObservableObject {
    @Published public var user: UserJSON?

    public lazy var userPublisher: AnyPublisher<UserJSON?, Never> = {
        $user.removeDuplicates().eraseToAnyPublisher()
    }()

    private let gateway: SpotifyUserProfileGateway

    private var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, gateway: SpotifyUserProfileGateway) {
        self.gateway = gateway

        auth.statePublisher
            .print("UserManagerImplementation.init")
            .receive(on: RunLoop.main)
            .map { authState -> AnyPublisher<UserJSON, Error> in
                print("UserMngr.auth.statePublisher: \(authState)")
                switch authState {
                case .loggedIn:
                    return self.getUser()
                case .notLoggedIn, .error:
                    self.user = nil
                    return Empty<UserJSON, Error>(completeImmediately: true).eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .print("UserManagerImplementation.init2")
            .sink { _ in } receiveValue: { self.user = $0 }
            .store(in: &bag)
    }

    public func getUser() -> AnyPublisher<UserJSON, Error> {
        return gateway.user().print("UserManager.getUser()")
            .eraseToAnyPublisher()
    }
}
