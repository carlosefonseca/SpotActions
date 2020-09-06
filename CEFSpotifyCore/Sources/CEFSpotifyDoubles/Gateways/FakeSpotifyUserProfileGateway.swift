//
// FakeSpotifyUserProfileGateway.swift
//

import Foundation
import CEFSpotifyCore
import Combine

class FakeSpotifyUserProfileGateway: SpotifyUserProfileGateway {
    func user() -> AnyPublisher<UserJSON, Error> {
        return Just(self.userJson!).setFailureType(to: Error.self).eraseToAnyPublisher()
    }


    var userJson: UserJSON?

//    func user(callback: @escaping (Result<SpotifyWebApi.UserProfile.Response, SpotifyRequestError>) -> Void) {
//        if let userJson = userJson {
//            callback(.success(userJson))
//        } else {
//            callback(.failure(.requestError(error: nil)))
//        }
//    }
}
