//
//  INDetailsOfTrackAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum INDetailsOfTrackAppEnum: String, AppEnum {
    case title
    case artists
    case album
    case duration
    case albumArtwork

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Details Of Track")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .title: "title",
        .artists: "artists",
        .album: "album",
        .duration: "duration",
        .albumArtwork: "album artwork"
    ]
}

