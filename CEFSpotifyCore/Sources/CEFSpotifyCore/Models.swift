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
    var name: String? { get }
}

public protocol Track: HasUri, Hashable {
    associatedtype SomeArtist: Artist
    var artists: [SomeArtist]? { get }
    var title: String? { get }
    var durationMs: Int? { get }
    var id: SpotifyID { get }
    var externalIdsStr: [String]? { get }
    var linkedTrackId: String? { get }
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

public typealias ErrorMessage = String
extension ErrorMessage: Error {}
extension ErrorMessage: LocalizedError {
    public var errorDescription: String? { self }
    public var failureReason: String? { self }
}
