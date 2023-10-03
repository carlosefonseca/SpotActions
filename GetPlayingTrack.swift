//
//  GetPlayingTrack.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetPlayingTrack: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetPlayingTrackIntent"

    static var title: LocalizedStringResource = "Get Playing Track"
    static var description = IntentDescription("")

    static var parameterSummary: some ParameterSummary {
        Summary("Get currently playing track")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: ()) {  in
            DisplayRepresentation(
                title: "Get currently playing track",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<INTrackAppEntity> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: INTrackAppEntity(/* fill in result initializer here */))
    }
}


