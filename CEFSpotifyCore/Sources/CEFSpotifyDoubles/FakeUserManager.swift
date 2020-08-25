//
//  FakeUserManager.swift
//

import Foundation
import Combine
import CEFSpotifyCore

public class FakeUserManager: UserManager {
    @Published public var user: UserJSON?

    public lazy var userPublisher: AnyPublisher<UserJSON?, Never> = {
        $user.removeDuplicates().eraseToAnyPublisher()
    }()

    var fakeUser: UserJSON?
    var getUserShouldFail = false

    public init(fakeUser: UserJSON? = nil) {
        self.fakeUser = fakeUser
    }

    public func getUser(completion: @escaping (Result<UserJSON, SpotifyRequestError>) -> Void) {
        if getUserShouldFail {
            completion(.failure(SpotifyRequestError.requestError(error: nil)))
        } else {
            user = fakeUser
            completion(.success(fakeUser!))
        }
    }
}
