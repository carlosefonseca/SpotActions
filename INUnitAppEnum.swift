//
//  INUnitAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum INUnitAppEnum: String, AppEnum {
    case tracks
    case minutes
    case hours

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "IN Unit")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .tracks: "tracks",
        .minutes: "minutes",
        .hours: "hours"
    ]
}

