//
//  INLimitModeAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum INLimitModeAppEnum: String, AppEnum {
    case first
    case last
    case any

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "IN Limit Mode")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .first: "first",
        .last: "last",
        .any: "any"
    ]
}

