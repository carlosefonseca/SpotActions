//
//  GetDetailsOfTrack.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetDetailsOfTrack: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetDetailsOfTrackIntent"

    static var title: LocalizedStringResource = "Get Details Of Track"
    static var description = IntentDescription("")

    @Parameter(title: "Detail", default: .artists)
    var detail: INDetailsOfTrackAppEnum?

    @Parameter(title: "Track")
    var track: INTrackAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$detail) from \(\.$track)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$detail, \.$track)) { detail, track in
            DisplayRepresentation(
                title: "Get \(detail!) from \(track!)",
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
    static func detailParameterDisambiguationIntro(count: Int, detail: INDetailsOfTrackAppEnum) -> Self {
        "There are \(count) options matching ‘\(detail)’."
    }
    static func detailParameterConfirmation(detail: INDetailsOfTrackAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(detail)’?"
    }
}

