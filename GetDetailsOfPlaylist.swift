//
//  GetDetailsOfPlaylist.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetDetailsOfPlaylist: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetDetailsOfPlaylistIntent"

    static var title: LocalizedStringResource = "Get Details Of Playlist"
    static var description = IntentDescription("")

    @Parameter(title: "Detail")
    var detail: INDetailsOfPlaylistAppEnum?

    @Parameter(title: "Playlist")
    var playlist: INPlaylistAppEntity?

    static var parameterSummary: some ParameterSummary {
        
        Summary("Get \(\.$detail) from \(\.$playlist)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$detail, \.$playlist)) { detail, playlist in
            DisplayRepresentation(
                title: "Get \(detail!) from \(playlist!)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: String(/* fill in result initializer here */))
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func detailParameterDisambiguationIntro(count: Int, detail: INDetailsOfPlaylistAppEnum) -> Self {
        "There are \(count) options matching ‘\(detail)’."
    }
    static func detailParameterConfirmation(detail: INDetailsOfPlaylistAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(detail)’?"
    }
}

