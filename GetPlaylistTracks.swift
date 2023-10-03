//
//  GetPlaylistTracks.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetPlaylistTracks: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetPlaylistTracksIntent"

    static var title: LocalizedStringResource = "Get Playlist Tracks"
    static var description = IntentDescription("")

    @Parameter(title: "Option", default: .allTracks)
    var option: GetPlaylistTracksOptionAppEnum?

    @Parameter(title: "option")
    var playlist: INPlaylistAppEntity?

    static var parameterSummary: some ParameterSummary {
        When(\.$option, .equalTo, .allTracks) {
            Summary("Get \(\.$option) of \(\.$playlist)")
        } otherwise: {
            Summary("Get \(\.$option)")
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$playlist, \.$option)) { playlist, option in
            DisplayRepresentation(
                title: "Get \(option!) of \(playlist!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$option)) { option in
            DisplayRepresentation(
                title: "Get \(option!)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<INTrackAppEntity> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: INTrackAppEntity(/* fill in result initializer here */))
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func optionParameterDisambiguationIntro(count: Int, option: GetPlaylistTracksOptionAppEnum) -> Self {
        "There are \(count) options matching ‘\(option)’."
    }
    static func optionParameterConfirmation(option: GetPlaylistTracksOptionAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(option)’?"
    }
    static func responseSuccess(result: INTrackAppEntity) -> Self {
        "\(result)"
    }
    static func responseFailure(error: String) -> Self {
        "\(error)"
    }
}

