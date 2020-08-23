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

    init(auth: SpotifyAuthManager, userManager: UserManager) {
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
                completion(.success(result: user.display_name ?? user.id!))
            case .failure(let error):
                completion(.failure(error: error.errorDescription ?? String(describing: error)))
            }
        }
    }
}
