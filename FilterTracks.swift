//
//  FilterTracks.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct FilterTracks: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "FilterTracksIntent"

    static var title: LocalizedStringResource = "Filter Tracks"
    static var description = IntentDescription("")

    @Parameter(title: "Mode")
    var mode: FilterTracksModeAppEnum?

    @Parameter(title: "Tracks")
    var tracks: [INTrackAppEntity]?

    @Parameter(title: "Filter")
    var filter: FilterTracksMatcherAppEnum?

    @Parameter(title: "Artists")
    var andArtists: [String]?

    @Parameter(title: "Titles")
    var andTitles: [String]?

    @Parameter(title: "Is Regex")
    var andIsRegex: Bool?

    @Parameter(title: "Other Playlist")
    var otherPlaylist: INPlaylistAppEntity?

    @Parameter(title: "Other Tracks")
    var otherTracks: [INTrackAppEntity]?

    @Parameter(title: "Titles")
    var orTitles: [String]?

    @Parameter(title: "Artists")
    var orArtists: [String]?

    @Parameter(title: "Is Regex")
    var orIsRegex: Bool?

    @Parameter(title: "Limit Mode", default: .first)
    var limitMode: INLimitModeAppEnum?

    @Parameter(title: "Amount", default: 10)
    var amount: Int?

    @Parameter(title: "Unit", default: .tracks)
    var unit: INUnitAppEnum?

    static var parameterSummary: some ParameterSummary {
        Switch(\.$filter) {
            Case(.titleAndArtist) {
                Summary()
            }
            Case(.titleAndArtist) {
                Summary()
            }
            Case(.titleAndArtist) {
                Summary()
            }
            Case(.existInPlaylist) {
                Summary("\(\.$mode) tracks from \(\.$tracks) that \(\.$filter)  \(\.$otherPlaylist)")
            }
            Case(.existInTracks) {
                Summary("\(\.$mode) tracks from \(\.$tracks) that \(\.$filter) \(\.$otherTracks)")
            }
            Case(.titleOrArtist) {
                Summary()
            }
            Case(.titleOrArtist) {
                Summary()
            }
            Case(.titleOrArtist) {
                Summary()
            }
            Case(.limit) {
                Summary()
            }
            Case(.limit) {
                Summary()
            }
            Case(.limit) {
                Summary()
            }
            DefaultCase {
                Summary("\(\.$mode) tracks from \(\.$tracks) that \(\.$filter)")
            }
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$mode, \.$tracks, \.$filter, \.$andArtists, \.$andTitles, \.$andIsRegex)) { mode, tracks, filter, andArtists, andTitles, andIsRegex in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(tracks!, format: .list(type: .and)) that \(filter!) \(andTitles!, format: .list(type: .and)) and \(andArtists!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$tracks, \.$filter, \.$orTitles, \.$orArtists, \.$orIsRegex)) { mode, tracks, filter, orTitles, orArtists, orIsRegex in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(tracks!, format: .list(type: .and)) that \(filter!) \(orTitles!, format: .list(type: .and)) or \(orArtists!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$tracks, \.$filter, \.$amount, \.$unit, \.$limitMode)) { mode, tracks, filter, amount, unit, limitMode in
            DisplayRepresentation(
                title: "\(mode!) subset of tracks \(filter!) to \(limitMode!) \(amount!) \(unit!) of \(tracks!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$tracks, \.$filter, \.$otherPlaylist)) { mode, tracks, filter, otherPlaylist in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(tracks!, format: .list(type: .and)) that \(filter!)  \(otherPlaylist!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$tracks, \.$filter, \.$otherTracks)) { mode, tracks, filter, otherTracks in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(tracks!, format: .list(type: .and)) that \(filter!) \(otherTracks!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$tracks, \.$filter)) { mode, tracks, filter in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(tracks!, format: .list(type: .and)) that \(filter!)",
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
    static func modeParameterDisambiguationIntro(count: Int, mode: FilterTracksModeAppEnum) -> Self {
        "There are \(count) options matching ‘\(mode)’."
    }
    static func modeParameterConfirmation(mode: FilterTracksModeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(mode)’?"
    }
    static func filterParameterDisambiguationIntro(count: Int, filter: FilterTracksMatcherAppEnum) -> Self {
        "There are \(count) options matching ‘\(filter)’."
    }
    static func filterParameterConfirmation(filter: FilterTracksMatcherAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(filter)’?"
    }
    static var otherPlaylistParameterConfiguration: Self {
        "Other Playlist"
    }
    static func limitModeParameterDisambiguationIntro(count: Int, limitMode: INLimitModeAppEnum) -> Self {
        "There are \(count) options matching ‘\(limitMode)’."
    }
    static func limitModeParameterConfirmation(limitMode: INLimitModeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(limitMode)’?"
    }
    static func unitParameterDisambiguationIntro(count: Int, unit: INUnitAppEnum) -> Self {
        "There are \(count) options matching ‘\(unit)’."
    }
    static func unitParameterConfirmation(unit: INUnitAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(unit)’?"
    }
    static func responseSuccess(result: INTrackAppEntity) -> Self {
        "\(result)"
    }
    static func responseFailure(error: String) -> Self {
        "\(error)"
    }
}

