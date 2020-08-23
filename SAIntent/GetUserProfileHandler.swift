//
//  GetUserProfileHandler.swift
//  SAIntent
//
//  Created by carlos.fonseca on 23/08/2020.
//

import Intents

class GetUserProfileHandler : NSObject, GetUserProfileIntentHandling {

    func handle(intent: GetUserProfileIntent, completion: @escaping (GetUserProfileIntentResponse) -> Void) {
        completion(.success(result: "carlos"))
    }


}
