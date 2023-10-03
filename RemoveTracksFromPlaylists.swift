//
//  RemoveTracksFromPlaylists.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct RemoveTracksFromPlaylists: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "RemoveTracksFromPlaylistsIntent"

    static var title: LocalizedStringResource = "Remove Tracks From Playlists"
    static var description = IntentDescription("")

    @Parameter(title: "Tracks")
    var tracks: [INTrackAppEntity]?

    @Parameter(title: "Playlists")
    var playlists: [INPlaylistAppEntity]?

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$tracks) from \(\.$playlists)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$tracks, \.$playlists)) { tracks, playlists in
            DisplayRepresentation(
                title: "Remove \(tracks!, format: .list(type: .and)) from \(playlists!, format: .list(type: .and))",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        // TODO: Place your refactored intent handler code here.
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func playlistsParameterDisambiguationIntro(count: Int, playlists: INPlaylistAppEntity) -> Self {
        "There are \(count) options matching ‘\(playlists)’."
    }
    static func playlistsParameterConfirmation(playlists: INPlaylistAppEntity) -> Self {
        "Just to confirm, you wanted ‘\(playlists)’?"
    }
}

