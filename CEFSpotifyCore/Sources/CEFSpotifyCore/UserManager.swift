//
//  UserManager.swift
//

import Foundation
import Combine

public protocol UserManager {
    var user: UserJSON? { get }
    var userPublished: Published<UserJSON?> { get }
    var userPublisher: Published<UserJSON?>.Publisher { get }

    func getUser(completion: @escaping (Result<UserJSON, SpotifyRequestError>) -> Void)
}

public class UserManagerImplementation: UserManager, ObservableObject {

    @Published public var user: UserJSON?
    public var userPublished: Published<UserJSON?> { _user }
    public var userPublisher: Published<UserJSON?>.Publisher { $user }

    private let gateway: SpotifyUserProfileGateway

    private var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, gateway: SpotifyUserProfileGateway) {
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
