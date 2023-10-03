//
//  INArtistAppEntity.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct INArtistAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Artist")

    @Property(title: "Uri")
    var uri: String?

    struct INArtistAppEntityQuery: EntityQuery {
        func entities(for identifiers: [INArtistAppEntity.ID]) async throws -> [INArtistAppEntity] {
            // TODO: return INArtistAppEntity entities with the specified identifiers here.
            return []
        }

        func suggestedEntities() async throws -> [INArtistAppEntity] {
            // TODO: return likely INArtistAppEntity entities here.
            // This method is optional; the default implementation returns an empty array.
            return []
        }
    }
    static var defaultQuery = INArtistAppEntityQuery()

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

