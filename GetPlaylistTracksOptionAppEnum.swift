//
//  GetPlaylistTracksOptionAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum GetPlaylistTracksOptionAppEnum: String, AppEnum {
    case recentTracks
    case allTracks

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Get Playlist Tracks Option")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .recentTracks: "recently played tracks",
        .allTracks: "all tracks"
    ]
}

