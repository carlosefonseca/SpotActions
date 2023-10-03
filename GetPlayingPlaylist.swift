//
//  GetPlayingPlaylist.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetPlayingPlaylist: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetPlayingPlaylistIntent"

    static var title: LocalizedStringResource = "Get Playing Playlist"
    static var description = IntentDescription("")

    static var parameterSummary: some ParameterSummary {
        Summary
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction { () in
            DisplayRepresentation(
                title: "",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<INPlaylistAppEntity> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: INPlaylistAppEntity(/* fill in result initializer here */))
    }
}


