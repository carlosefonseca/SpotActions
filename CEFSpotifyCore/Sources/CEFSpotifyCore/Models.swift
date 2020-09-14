//
// Models.swift
//

import Foundation

public protocol HasUri {
    var uri: String? { get }
}

public extension HasUri {
    var spotifyUri: SpotifyURI? { uri }
}

public protocol Artist: HasUri {
    var name: String { get }
}

public protocol Track: HasUri {
    associatedtype SomeArtist: Artist
    var artists: [SomeArtist]? { get }
    var title: String? { get }
    var durationMs: Int? { get }
}

public protocol Playlist: HasUri {
    var totalTracks: Int? { get }
}

public protocol User: HasUri {
    var displayName: String? { get }
    var email: String? { get }
    var country: String? { get }
    var product: String? { get }
}
