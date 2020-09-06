//
//  File.swift
//
//
//  Created by carlos.fonseca on 23/08/2020.
//

import Foundation

public struct UserJSON: Codable, Equatable, CustomStringConvertible {
    public var id: String?
    public var display_name: String?
    public var email: String?
    public var country: String?
    //   public var external_urls : [String:String]?
    //   public var followers : String?
    public var href: String?
    //   public var images : String?
    public var product: String?
    public var type: String?
    public var uri: String?

    public init() {}

    public var description: String {
        "UserJSON(\(id ?? "-"),\(display_name ?? "-"))"
    }
}

public struct PlaylistJSON: Codable, Equatable {
    /// Returns true if context is not search and the owner allows other users to modify the playlist. Otherwise returns false.
    public var collaborative: Bool?
    /// The playlist description. Only returned for modified, verified playlists, otherwise null.
    public var description: String?
    /// an external URL object    Known external URLs for this playlist.
    public var external_urls: ExternalUrlJSON?
    // var followers   : a followers object    Information about the followers of the playlist.
    /// A link to the Web API endpoint providing full details of the playlist.
    public var href: String?
    /// The Spotify ID for the playlist.
    public var id: String?
    /// Images for the playlist. The array may be empty or contain up to three images. The images are returned by size in descending order. See Working with Playlists.Note: If returned, the source URL for the image ( url ) is temporary and will expire in less than a day.
    public var images: [ImageJSON]??
    /// The name of the playlist.
    public var name: String?
    /// The user who owns the playlist
    public var owner: PublicUserJSON?
    // var public:    Bool or null    The playlist’s public/private status: true the playlist is public, false the playlist is private, null the playlist status is not relevant. For more about public/private status, see Working with Playlists.
    /// The version identifier for the current playlist. Can be supplied in other requests to target a specific playlist version: see Remove tracks from a playlist
    public var snapshot_id: String?
    /// array of playlist track objects inside a paging object    Information about the tracks of the playlist.
    public var tracks: PagedTracksJSON?
    // var type:    String    The object type: “playlist”
    /// The Spotify URI for the playlist.
    public var uri: String?
}

public struct ImageJSON: Codable, Equatable {
    public var url: String?
    public var height: Int?
    public var width: Int?
}

public struct PublicUserJSON: Codable, Equatable {
    /// The name displayed on the user’s profile. null if not available.
    public var display_name: String?
    /// Known public external URLs for this user.
    public var external_urls: ExternalUrlJSON?
    // /// Information about the followers of this user.
    // var followers  :  A followers object
    /// A link to the Web API endpoint for this user.
    public var href: String?
    /// The Spotify user ID for this user.
    public var id: String?
    /// The user’s profile image.
    public var images: [ImageJSON]??
    /// The object type: “user”
    public var type: String?
    /// The Spotify URI for this user.
    public var uri: String?
}

public struct PagingJSON<T>: Codable, Equatable where T: Codable, T: Equatable {
    /// A link to the Web API endpoint returning the full result of the request.
    public var href: String?
    /// The requested data.
    public var items: [T]?
    /// The maximum number of items in the response (as set in the query or by default).
    public var limit: Int?
    /// URL to the next page of items. ( null if none)
    public var next: String?
    /// The offset of the items returned (as set in the query or by default).
    public var offset: Int?
    /// URL to the previous page of items. ( null if none)
    public var previous: String?
    /// The maximum number of items available to return.
    public var total: Int?
}

public struct TrackJSON: Codable, Equatable {
    /// The artists who performed the track. Each artist object includes a link in href to more detailed information about the artist.
    public var artists: [ArtistJSON]?
    /// A list of the countries in which the track can be played, identified by their ISO 3166-1 alpha-2 code.
    public var available_markets: [String]?
    /// The disc number (usually 1 unless the album consists of more than one disc).
    public var disc_number: Int?
    /// The track length in milliseconds.
    public var duration_ms: Int?
    /// Whether or not the track has explicit lyrics ( true = yes it does; false = no it does not OR unknown).
    public var explicit: Bool?
    /// External URLs for this track.
    public var external_urls: ExternalUrlJSON?
    /// A link to the Web API endpoint providing full details of the track.
    public var href: String?
    /// The Spotify ID for the track.
    public var id: String?
    /// Part of the response when Track Relinking is applied. If true , the track is playable in the given market. Otherwise false.
    public var is_playable: Bool?
    //    /// Part of the response when Track Relinking is applied and is only part of the response if the track linking, in fact, exists. The requested track has been replaced with a different track. The track in the linked_from object contains information about the originally requested track.
    //    public var linked_from:a linked track object?
    //    /// Part of the response when Track Relinking is applied, the original track is not available in the given market, and Spotify did not have any tracks to relink it with. The track response will still contain metadata for the original track, and a restrictions object containing the reason why the track is not available: "restrictions" : {"reason" : "market"}
    //    public var restrictions:a restrictions object?
    /// The name of the track.
    public var name: String?
    /// A URL to a 30 second preview (MP3 format) of the track.
    public var preview_url: String?
    /// The number of the track. If an album has several discs, the track number is the number on the specified disc.
    public var track_number: Int?
    /// The object type: “track”.
    public var type: String?
    /// The Spotify URI for the track.
    public var uri: String?
    /// Whether or not the track is from a local file.
    public var is_local: Bool?
}

public struct ArtistJSON: Codable, Equatable {
    /// Known external URLs for this artist.
    public var external_urls: ExternalUrlJSON?
    /// A link to the Web API endpoint providing full details of the artist.
    public var href: String?
    /// The Spotify ID for the artist.
    public var id: String?
    /// The name of the artist.
    public var name: String?
    /// The object type: "artist"
    public var type: String?
    /// The Spotify URI for the artist.
    public var uri: String?
}

public typealias ExternalUrlJSON = [String: String]

public typealias PagedTracksJSON = PagingJSON<TrackJSON>

public typealias PagedPlaylistsJSON = PagingJSON<PlaylistJSON>

