//
//  INPlaylistAppEntity.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct INPlaylistAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Playlist")

    @Property(title: "Track Count")
    var trackCount: Int?

    @Property(title: "Uri")
    var uri: String?

    @Property(title: "Image Url")
    var imageUrl: URL?

    @Property(title: "Image Width")
    var imageWidth: Int?

    @Property(title: "Image Height")
    var imageHeight: Int?

    @Property(title: "Owner Id")
    var owner: String?

    struct INPlaylistAppEntityQuery: EntityQuery {
        func entities(for identifiers: [INPlaylistAppEntity.ID]) async throws -> [INPlaylistAppEntity] {
            // TODO: return INPlaylistAppEntity entities with the specified identifiers here.
            return []
        }

        func suggestedEntities() async throws -> [INPlaylistAppEntity] {
            // TODO: return likely INPlaylistAppEntity entities here.
            // This method is optional; the default implementation returns an empty array.
            return []
        }
    }
    static var defaultQuery = INPlaylistAppEntityQuery()

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

