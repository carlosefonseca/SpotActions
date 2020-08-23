//
//  IntentHandler.swift
//  SAIntent
//
//  Created by carlos.fonseca on 23/08/2020.
//

import Intents

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.

        switch intent {
        case is GetUserProfileIntent:
            return GetUserProfileHandler()
        default:
            fatalError("No handler for this intent")
        }
    }
}
