//
//  INMixTypeAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum INMixTypeAppEnum: String, AppEnum {
    case concat
    case alternate
    case mix

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "IN Mix Type")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .concat: "Concatenate",
        .alternate: "Alternate",
        .mix: "Mix"
    ]
}

