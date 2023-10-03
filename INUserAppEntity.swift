//
//  INUserAppEntity.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct INUserAppEntity: TransientAppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "User")

    @Property(title: "Email")
    var email: String?

    @Property(title: "Country")
    var country: String?

    @Property(title: "Uri")
    var uri: String?

    @Property(title: "Product")
    var product: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Unimplemented")
    }

    init() {
    }
}

