//
//  MixTracks.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct MixTracks: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "MixTracksIntent"

    static var title: LocalizedStringResource = "Mix Tracks"
    static var description = IntentDescription("Join tracks from multiple playlists or variables into a single set of tracks.")

    @Parameter(title: "Mode", default: .mixSuffled)
    var mode: INMixTypeAppEnum?

    @Parameter(title: "Playlists")
    var playlists: [INPlaylistAppEntity]?

    @Parameter(title: "Track Variables")
    var amount: Int?

    @Parameter(title: "Tracks 1 ")
    var tracks1: [INTrackAppEntity]?

    @Parameter(title: "Tracks 2")
    var tracks2: [INTrackAppEntity]?

    @Parameter(title: "Tracks 3")
    var tracks3: [INTrackAppEntity]?

    @Parameter(title: "Tracks 4")
    var tracks4: [INTrackAppEntity]?

    @Parameter(title: "Tracks 5")
    var tracks5: [INTrackAppEntity]?

    @Parameter(title: "Tracks 6")
    var tracks6: [INTrackAppEntity]?

    @Parameter(title: "Tracks 7")
    var tracks7: [INTrackAppEntity]?

    @Parameter(title: "Tracks 8")
    var tracks8: [INTrackAppEntity]?

    @Parameter(title: "Tracks 9")
    var tracks9: [INTrackAppEntity]?

    @Parameter(title: "Tracks 10")
    var tracks10: [INTrackAppEntity]?

    static var parameterSummary: some ParameterSummary {
        When(\.$amount, .greaterThan, 0) {
            When(\.$amount, .greaterThan, 1) {
                When(\.$amount, .greaterThan, 2) {
                    When(\.$amount, .greaterThan, 3) {
                        When(\.$amount, .greaterThan, 4) {
                            When(\.$amount, .greaterThan, 5) {
                                When(\.$amount, .greaterThan, 6) {
                                    When(\.$amount, .greaterThan, 7) {
                                        When(\.$amount, .greaterThanOrEqualTo, 9) {
                                            When(\.$amount, .greaterThanOrEqualTo, 10) {
                                                Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3), \(\.$tracks4), \(\.$tracks5), \(\.$tracks6), \(\.$tracks7), \(\.$tracks8), \(\.$tracks9), \(\.$tracks10)")
                                            } otherwise: {
                                                Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3), \(\.$tracks4), \(\.$tracks5), \(\.$tracks6), \(\.$tracks7), \(\.$tracks8), \(\.$tracks9)")
                                            }
                                        } otherwise: {
                                            Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3), \(\.$tracks4), \(\.$tracks5), \(\.$tracks6), \(\.$tracks7), \(\.$tracks8)")
                                        }
                                    } otherwise: {
                                        Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3), \(\.$tracks4), \(\.$tracks5), \(\.$tracks6), \(\.$tracks7)")
                                    }
                                } otherwise: {
                                    Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3), \(\.$tracks4), \(\.$tracks5), \(\.$tracks6)")
                                }
                            } otherwise: {
                                Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3), \(\.$tracks4), \(\.$tracks5)")
                            }
                        } otherwise: {
                            Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3), \(\.$tracks4)")
                        }
                    } otherwise: {
                        Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2), \(\.$tracks3)")
                    }
                } otherwise: {
                    Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1), \(\.$tracks2)")
                }
            } otherwise: {
                Summary("\(\.$mode) tracks from \(\.$playlists) and from \(\.$amount) \(\.$tracks1)")
            }
        } otherwise: {
            Summary("\(\.$mode) tracks from \(\.$playlists)") {
                \.$amount
            }
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$playlists, \.$tracks1, \.$tracks2, \.$tracks3, \.$tracks4, \.$tracks5, \.$tracks6, \.$tracks7, \.$tracks8, \.$tracks9, \.$tracks10, \.$mode, \.$amount)) { playlists, tracks1, tracks2, tracks3, tracks4, tracks5, tracks6, tracks7, tracks8, tracks9, tracks10, mode, amount in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and)), \(tracks4!, format: .list(type: .and)), \(tracks5!, format: .list(type: .and)), \(tracks6!, format: .list(type: .and)), \(tracks7!, format: .list(type: .and)), \(tracks8!, format: .list(type: .and)), \(tracks9!, format: .list(type: .and)), \(tracks10!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2, \.$tracks3, \.$tracks4, \.$tracks5, \.$tracks6, \.$tracks7, \.$tracks8, \.$tracks9)) { mode, playlists, amount, tracks1, tracks2, tracks3, tracks4, tracks5, tracks6, tracks7, tracks8, tracks9 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and)), \(tracks4!, format: .list(type: .and)), \(tracks5!, format: .list(type: .and)), \(tracks6!, format: .list(type: .and)), \(tracks7!, format: .list(type: .and)), \(tracks8!, format: .list(type: .and)), \(tracks9!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2, \.$tracks3, \.$tracks4, \.$tracks5, \.$tracks6, \.$tracks7, \.$tracks8)) { mode, playlists, amount, tracks1, tracks2, tracks3, tracks4, tracks5, tracks6, tracks7, tracks8 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and)), \(tracks4!, format: .list(type: .and)), \(tracks5!, format: .list(type: .and)), \(tracks6!, format: .list(type: .and)), \(tracks7!, format: .list(type: .and)), \(tracks8!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2, \.$tracks3, \.$tracks4, \.$tracks5, \.$tracks6, \.$tracks7)) { mode, playlists, amount, tracks1, tracks2, tracks3, tracks4, tracks5, tracks6, tracks7 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and)), \(tracks4!, format: .list(type: .and)), \(tracks5!, format: .list(type: .and)), \(tracks6!, format: .list(type: .and)), \(tracks7!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2, \.$tracks3, \.$tracks4, \.$tracks5, \.$tracks6)) { mode, playlists, amount, tracks1, tracks2, tracks3, tracks4, tracks5, tracks6 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and)), \(tracks4!, format: .list(type: .and)), \(tracks5!, format: .list(type: .and)), \(tracks6!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2, \.$tracks3, \.$tracks4, \.$tracks5)) { mode, playlists, amount, tracks1, tracks2, tracks3, tracks4, tracks5 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and)), \(tracks4!, format: .list(type: .and)), \(tracks5!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2, \.$tracks3, \.$tracks4)) { mode, playlists, amount, tracks1, tracks2, tracks3, tracks4 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and)), \(tracks4!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2, \.$tracks3)) { mode, playlists, amount, tracks1, tracks2, tracks3 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and)), \(tracks3!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1, \.$tracks2)) { mode, playlists, amount, tracks1, tracks2 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and)), \(tracks2!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount, \.$tracks1)) { mode, playlists, amount, tracks1 in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and)) and from \(amount!) \(tracks1!, format: .list(type: .and))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$mode, \.$playlists, \.$amount)) { mode, playlists, amount in
            DisplayRepresentation(
                title: "\(mode!) tracks from \(playlists!, format: .list(type: .and))",
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
    static func modeParameterDisambiguationIntro(count: Int, mode: INMixTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(mode)’."
    }
    static func modeParameterConfirmation(mode: INMixTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(mode)’?"
    }
}

