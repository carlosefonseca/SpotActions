//
//  UserManager.swift
//

import Foundation
import Combine

public protocol UserManager {
    var user: UserJSON? { get }
    var userPublisher: AnyPublisher<UserJSON?, Never> { get }

    func getUser(completion: @escaping (Result<UserJSON, SpotifyRequestError>) -> Void)
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
            .print()
//            .receive(on: RunLoop.main)
            .sink { authState in
                print("UserMngr.auth.statePublisher: \(authState)")
                switch authState {
                case .loggedIn:
                    self.getUser(completion: { print($0) })
                case .notLoggedIn, .error:
                    self.user = nil
                }
            }.store(in: &bag)
    }

    public func getUser(completion: @escaping (Result<UserJSON, SpotifyRequestError>) -> Void) {
        gateway.user { result in
            switch result {
            case .success(let user):
                self.user = user
            case .failure(let error):
                self.user = nil
                print(error)
            }
            completion(result)
        }
    }
}
