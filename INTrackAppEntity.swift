//
//  INTrackAppEntity.swift
//  SpotActions
//
//  Created by Carlos Fonseca on 03/10/2023.
//

import AppIntents
import Foundation

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct INTrackAppEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Track")

    @Property(title: "Uri")
    var uri: String

    @Property(title: "Title")
    var title: String

    @Property(title: "Artists")
    var artists: [INArtistAppEntity]

    @Property(title: "Duration")
    var duration: Measurement<UnitDuration>

    @Property(title: "Duration (ms)")
    var durationMillis: Int

    @Property(title: "External Ids")
    var externalIds: [INExternalIdAppEntity]?

    @Property(title: "Linked Track Identifier")
    var linkedTrackId: String?

    @Property(title: "Album Name")
    var albumName: String

    @Property(title: "Album Art Url")
    var albumArtUrl: URL?

    @Property(title: "Album Art Width")
    var albumArtW: Int?

    @Property(title: "Album Art Height")
    var albumArtH: Int?

    struct INTrackAppEntityQuery: EntityQuery {
        func entities(for identifiers: [INTrackAppEntity.ID]) async throws -> [INTrackAppEntity] {
            // TODO: return INTrackAppEntity entities with the specified identifiers here.
            []
        }

        func suggestedEntities() async throws -> [INTrackAppEntity] {
            // TODO: return likely INTrackAppEntity entities here.
            // This method is optional; the default implementation returns an empty array.
            []
        }
    }

    static var defaultQuery = INTrackAppEntityQuery()

    var id: String
//    var displayString: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)",
                              subtitle: "\(artists.map(\.displayString).joined(separator: ", "))")
    }

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
