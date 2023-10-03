//
//  INExternalIdAppEntity.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct INExternalIdAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "External Id")

    @Property(title: "Type")
    var key: String?

    @Property(title: "Value")
    var value: String?

    struct INExternalIdAppEntityQuery: EntityQuery {
        func entities(for identifiers: [INExternalIdAppEntity.ID]) async throws -> [INExternalIdAppEntity] {
            // TODO: return INExternalIdAppEntity entities with the specified identifiers here.
            return []
        }

        func suggestedEntities() async throws -> [INExternalIdAppEntity] {
            // TODO: return likely INExternalIdAppEntity entities here.
            // This method is optional; the default implementation returns an empty array.
            return []
        }
    }
    static var defaultQuery = INExternalIdAppEntityQuery()

    var id: String // if your identifier is not a String, conform the entity to EntityIdentifierConvertible.
    var displayString: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }

    init(id: String, displayString: String) {
        self.id = id
        self.displayString = displayString
    }
}

