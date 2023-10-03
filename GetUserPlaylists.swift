//
//  GetUserPlaylists.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetUserPlaylists: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetUserPlaylistsIntent"

    static var title: LocalizedStringResource = "Get User Playlists"
    static var description = IntentDescription("ToDo")

    @Parameter(title: "Fetch", default: .all)
    var fetchPageMode: FetchPageModeAppEnum?

    @Parameter(title: "Filter")
    var filter: String?

    @Parameter(title: "Owner")
    var owner: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$fetchPageMode) user playlists") {
            \.$filter
            \.$owner
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$filter, \.$fetchPageMode, \.$owner)) { filter, fetchPageMode, owner in
            DisplayRepresentation(
                title: "Get \(fetchPageMode!) user playlists",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<INPlaylistAppEntity> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: INPlaylistAppEntity(/* fill in result initializer here */))
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func fetchPageModeParameterDisambiguationIntro(count: Int, fetchPageMode: FetchPageModeAppEnum) -> Self {
        "There are \(count) options matching ‘\(fetchPageMode)’."
    }
    static func fetchPageModeParameterConfirmation(fetchPageMode: FetchPageModeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(fetchPageMode)’?"
    }
    static func responseSuccess(result: INPlaylistAppEntity) -> Self {
        "\(result)"
    }
    static func responseFailure(error: String) -> Self {
        "\(error)"
    }
}

