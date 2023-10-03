//
//  INDetailsOfPlaylistAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum INDetailsOfPlaylistAppEnum: String, AppEnum {
    case tracks
    case name
    case image
    case owner
    case description
    case trackCount

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Details Of Playlist")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .tracks: "tracks",
        .name: "name",
        .image: "image",
        .owner: "owner",
        .description: "description",
        .trackCount: "track count"
    ]
}

