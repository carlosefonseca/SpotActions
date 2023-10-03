//
//  FilterTracksModeAppEnum.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum FilterTracksModeAppEnum: String, AppEnum {
    case select
    case reject

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Filter Tracks Mode")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .select: "Select",
        .reject: "Reject"
    ]
}

