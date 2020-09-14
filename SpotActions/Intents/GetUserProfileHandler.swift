//
//  GetUserProfileHandler.swift
//  SAIntent
//
//  Created by carlos.fonseca on 23/08/2020.
//

import Intents
import CEFSpotifyCore
import Combine

class GetUserProfileHandler: NSObject, GetUserProfileIntentHandling {

    let auth: SpotifyAuthManager
    let userManager: UserManager

    var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, userManager: UserManager) {
        self.auth = auth
        self.userManager = userManager
    }

    func handle(intent: GetUserProfileIntent, completion: @escaping (GetUserProfileIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        userManager.getUser().sink(receiveCompletion: { compl in
            if case .failure(let error) = compl {
                completion(.failure(error: error.localizedDescription))
            }
        }, receiveValue: { user in
            let u = INUser(identifier: user.id, display: user.display_name!)
            u.email = user.email
            u.country = user.country
            u.product = user.product
            u.uri = user.uri
            completion(.success(result: u))
        }).store(in: &bag)
    }
}
