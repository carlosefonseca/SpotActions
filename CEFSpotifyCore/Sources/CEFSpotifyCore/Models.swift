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
    var id: SpotifyID { get }
    var name: String? { get }
}

public protocol Track: HasUri, CustomStringConvertible {
    var title: String? { get }
    var durationMs: Int? { get }
    var id: SpotifyID { get }
    var externalIdsStr: [String]? { get }
    var linkedTrackId: String? { get }

    var artistIds: [SpotifyID] { get }
    var artistNames: [String] { get }
}

public protocol Playlist: HasUri {
    var id: SpotifyID { get }
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
