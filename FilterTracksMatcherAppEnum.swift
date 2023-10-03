//
//  FilterTracksMatcherAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum FilterTracksMatcherAppEnum: String, AppEnum {
    case titleAndArtist
    case titleOrArtist
    case existInPlaylist
    case existInTracks
    case dedup
    case limit

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Filter Tracks Matcher")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .titleAndArtist: "match title and artist",
        .titleOrArtist: "match title or artist",
        .existInPlaylist: "exist in playlist",
        .existInTracks: "exist in variable",
        .dedup: "are duplicated",
        .limit: "limited"
    ]
}

