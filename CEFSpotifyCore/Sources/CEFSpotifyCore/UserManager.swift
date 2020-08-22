//
//  UserManager.swift
//

import Foundation
import Combine

public protocol UserManager {
    var user: User? { get }
    var userPublished: Published<User?> { get }
    var userPublisher: Published<User?>.Publisher { get }

    func getUser(completion: @escaping (Result<User, SpotifyRequestError>) -> Void)
}

public class UserManagerImplementation: UserManager, ObservableObject {

    @Published public var user: User?
    public var userPublished: Published<User?> { _user }
    public var userPublisher: Published<User?>.Publisher { $user }

    private let gateway: SpotifyWebApiGateway

    private var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, gateway: SpotifyWebApiGateway) {
        self.gateway = gateway

        auth.statePublisher
            .receive(on: RunLoop.main)
            .sink { authState in
                switch authState {
                case .loggedIn:
                    self.getUser(completion: { print($0) })
                case .notLoggedIn, .error:
                    self.user = nil
                }
            }.store(in: &bag)
    }

    public func getUser(completion: @escaping (Result<User, SpotifyRequestError>) -> Void) {
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
