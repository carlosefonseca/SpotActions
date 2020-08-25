//
//  GetUserProfileHandler.swift
//  SAIntent
//
//  Created by carlos.fonseca on 23/08/2020.
//

import Intents
import CEFSpotifyCore

class GetUserProfileHandler: NSObject, GetUserProfileIntentHandling {

    let auth: SpotifyAuthManager
    let userManager: UserManager

    public init(auth: SpotifyAuthManager, userManager: UserManager) {
        self.auth = auth
        self.userManager = userManager
    }

    func handle(intent: GetUserProfileIntent, completion: @escaping (GetUserProfileIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        userManager.getUser { result in

            switch result {
            case .success(let user):
                let u = User(identifier: user.id, display: user.display_name!)
                u.email = user.email
                u.country = user.country
                u.product = user.product
                u.uri = user.uri
                completion(.success(result: u))
            case .failure(let error):
                completion(.failure(error: error.errorDescription ?? String(describing: error)))
            }
        }
    }
}

extension User {

    convenience init(from json: UserJSON) {
        self.init(identifier: json.id, display: json.display_name!)
        email = json.email
        country = json.country
        product = json.product
        uri = json.uri
    }
}
