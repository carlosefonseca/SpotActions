//
//  GetUserProfile.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetUserProfile: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetUserProfileIntent"

    static var title: LocalizedStringResource = "Get User Profile"
    static var description = IntentDescription("TODO")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Spotify User Profile")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(displayRepresentation: {
            DisplayRepresentation(
                title: "Get Spotify User Profile",
                subtitle: ""
            )
        })
    }

    func perform() async throws -> some IntentResult & ReturnsValue<INUserAppEntity> {

        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        userManager.getUser().sink(receiveCompletion: { compl in
            if case .failure(let error) = compl {
                completion(.failure(error: error.localizedDescription))
            }
        }, receiveValue: { user in
            let u = INUser(from: user)
            completion(.success(result: u))
        }).store(in: &bag)


        // TODO: Place your refactored intent handler code here.
        return .result(value: INUserAppEntity(/* fill in result initializer here */))
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func responseSuccess(result: INUserAppEntity) -> Self {
        "\(result)"
    }
    static func responseFailure(error: String) -> Self {
        "\(error)"
    }
}

