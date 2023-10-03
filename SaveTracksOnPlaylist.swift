//
//  SaveTracksOnPlaylist.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct SaveTracksOnPlaylist: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SaveTracksOnPlaylistIntent"

    static var title: LocalizedStringResource = "Save Tracks To Playlist"
    static var description = IntentDescription("")

    @Parameter(title: "Playlist")
    var playlist: INPlaylistAppEntity?

    @Parameter(title: "Tracks")
    var tracks: [INTrackAppEntity]?

    static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$tracks) to \(\.$playlist)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$playlist, \.$tracks)) { playlist, tracks in
            DisplayRepresentation(
                title: "Save \(tracks!, format: .list(type: .and)) to \(playlist!)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<INTrackAppEntity> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: INTrackAppEntity(/* fill in result initializer here */))
    }
}


