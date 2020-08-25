//
// FakeSpotifyUserProfileGateway.swift
//

import Foundation
import CEFSpotifyCore

class FakeSpotifyUserProfileGateway: SpotifyUserProfileGateway {

    var userJson: UserJSON?

    func user(callback: @escaping (Result<SpotifyWebApi.UserProfile.Response, SpotifyRequestError>) -> Void) {
        if let userJson = userJson {
            callback(.success(userJson))
        } else {
            callback(.failure(.requestError(error: nil)))
        }
    }
}
