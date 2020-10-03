//
//  SpotifyModels.swift
//  CEFSpotifyCore
//

import Foundation

public protocol ModelJSON: Codable, Equatable {}

public struct UserJSON: ModelJSON, CustomStringConvertible, User {
    public var id: String?
    public var displayName: String?
    public var email: String?
    public var country: String?
    //   public var externalUrls : [String:String]?
    //   public var followers : String?
    public var href: String?
    //   public var images : String?
    public var product: String?
    public var type: String?
    public var uri: String?

    public init() {}

    public var description: String {
        "UserJSON(\(id ?? "-"),\(displayName ?? "-"))"
    }
}

public struct PlaylistJSON: ModelJSON {
    /// Returns true if context is not search and the owner allows other users to modify the playlist. Otherwise returns false.
    public var collaborative: Bool?
    /// The playlist description. Only returned for modified, verified playlists, otherwise null.
    public var description: String?
    /// an external URL object    Known external URLs for this playlist.
    public var externalUrls: ExternalUrlJSON?
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
    public var snapshotId: String?
    /// array of playlist track objects inside a paging object    Information about the tracks of the playlist.
    public var tracks: PagedTracksJSON?
    // var type:    String    The object type: “playlist”
    /// The Spotify URI for the playlist.
    public var uri: String?

    public init(collaborative: Bool? = nil, description: String? = nil, externalUrls: ExternalUrlJSON? = nil, href: String? = nil, id: String? = nil, images: [ImageJSON]?? = nil, name: String? = nil, owner: PublicUserJSON? = nil, snapshotId: String? = nil, tracks: PagedTracksJSON? = nil, uri: String? = nil) {
        self.collaborative = collaborative
        self.description = description
        self.externalUrls = externalUrls
        self.href = href
        self.id = id
        self.images = images
        self.name = name
        self.owner = owner
        self.snapshotId = snapshotId
        self.tracks = tracks
        self.uri = uri
    }
}

extension PlaylistJSON: Playlist {
    public var totalTracks: Int? { tracks?.total }
}

public struct ImageJSON: ModelJSON {
    public var url: String?
    public var height: Int?
    public var width: Int?
}

public struct PublicUserJSON: ModelJSON {
    /// The name displayed on the user’s profile. null if not available.
    public var displayName: String?
    /// Known public external URLs for this user.
    public var externalUrls: ExternalUrlJSON?
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

public struct PagingJSON<T>: ModelJSON where T: ModelJSON {

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

    public init(href: String? = nil, items: [T]? = nil, limit: Int? = nil, next: String? = nil, offset: Int? = nil, previous: String? = nil, total: Int? = nil) {
        self.href = href
        self.items = items
        self.limit = limit
        self.next = next
        self.offset = offset
        self.previous = previous
        self.total = total
    }
}

public struct TrackJSON: ModelJSON, Hashable {
    /// The artists who performed the track. Each artist object includes a link in href to more detailed information about the artist.
    public var artists: [ArtistJSON]?
    /// A list of the countries in which the track can be played, identified by their ISO 3166-1 alpha-2 code.
    public var availableMarkets: [String]?
    /// The disc number (usually 1 unless the album consists of more than one disc).
    public var discNumber: Int?
    /// The track length in milliseconds.
    public var durationMs: Int?
    /// Whether or not the track has explicit lyrics ( true = yes it does; false = no it does not OR unknown).
    public var explicit: Bool?
    /// Known external IDs for the track.
    public var externalIds: ExternalIdsJSON?
    /// External URLs for this track.
    public var externalUrls: ExternalUrlJSON?
    /// A link to the Web API endpoint providing full details of the track.
    public var href: String?
    /// The Spotify ID for the track.
    public var id: SpotifyID
    /// Part of the response when Track Relinking is applied. If true , the track is playable in the given market. Otherwise false.
    public var isPlayable: Bool?
    /// Part of the response when Track Relinking is applied and is only part of the response if the track linking, in fact, exists. The requested track has been replaced with a different track. The track in the linkedFrom object contains information about the originally requested track.
    public var linkedFrom: TrackLinkJSON?
    /// Part of the response when Track Relinking is applied, the original track is not available in the given market, and Spotify did not have any tracks to relink it with. The track response will still contain metadata for the original track, and a restrictions object containing the reason why the track is not available: "restrictions" : {"reason" : "market"}
    public var restrictions: RestrictionsJSON?
    /// The name of the track.
    public var name: String?
    /// A URL to a 30 second preview (MP3 format) of the track.
    public var previewUrl: String?
    /// The number of the track. If an album has several discs, the track number is the number on the specified disc.
    public var trackNumber: Int?
    /// The object type: “track”.
    public var type: String?
    /// The Spotify URI for the track.
    public var uri: String?
    /// Whether or not the track is from a local file.
    public var isLocal: Bool?
}

extension TrackJSON: Track {
    public var title: String? { name }
    public var externalIdsStr: [String]? { externalIds?.compactMap { type, value in "\(type):\(value)" } }
    public var linkedTrackId: String? { linkedFrom?.id }
}

extension TrackJSON: CustomStringConvertible {
    public var description: String {
        return "TrackJSON[\(id), \(name ?? "name?"), \(artists?.map { $0.name ?? "?" }.joined(separator: ",") ?? "artists?")]"
    }
}

public extension TrackJSON {
    init(id: String) {
        self.id = id
    }
}

public struct ArtistJSON: Artist, ModelJSON, Hashable {
    /// Known external URLs for this artist.
    public var externalUrls: ExternalUrlJSON?
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

public typealias ExternalIdsJSON = [String: String]

public typealias PagedTracksJSON = PagingJSON<PageTrackJSON>

public typealias PagedPlaylistsJSON = PagingJSON<PlaylistJSON>

public typealias SpotifyID = String
public typealias SpotifyURI = String

public extension SpotifyURI {
    var splits: [String.SubSequence] { split(separator: ":") }

    var category: String {
        return String(splits[splits.count - 2])
    }

    var id: String {
        String(splits.last!)
    }
}

public struct PageTrackJSON: ModelJSON {
    var addedAt: String?
    var addedBy: AddedByJSON?
    var isLocal: Bool?
    var track: TrackJSON?
}

public struct AddedByJSON: ModelJSON {
    var externalUrls: ExternalUrlJSON?
    var href: String?
    var id: String?
    var type: String?
    var uri: String
}

struct URIListJSON: ModelJSON {
    var uris: [SpotifyURI]
    var position: Int?
}

public struct CurrentlyPlayingJSON: ModelJSON {
    /// A Context Object. Can be null.
    public var context: ContextJSON?
    /// Unix Millisecond Timestamp when data was fetched
    public var timestamp: Int
    /// Progress into the currently playing track or episode. Can be null.
    public var progressMs: Int?
    /// If something is currently playing.
    public var isPlaying: Bool
    /// The currently playing track or episode. Can be null.
    public var item: TrackJSON?
    /// The object type of the currently playing item. Can be one of track, episode, ad or unknown.
    public var currentlyPlayingType: String
    /// Allows to update the user interface based on which playback actions are available within the current context
    // public var actions: []
}

public struct ContextJSON: ModelJSON {
    /// The uri of the context.
    public var uri: String?
    /// The href of the context, or null if not available.
    public var href: String?
    /// The externalUrls of the context, or null if not available.
    public var externalUrls: ExternalUrlJSON
    /// The object type of the item’s context. Can be one of album, artist or playlist.
    public var type: String?
}

public struct TrackLinkJSON: ModelJSON, Hashable {
    /// Known external URLs for this track.
    public var externalUrls: ExternalUrlJSON?
    /// A link to the Web API endpoint providing full details of the track.
    public var href: String?
    /// The Spotify ID for the track.
    public var id: SpotifyID?
    /// The object type: “track”.
    public var type: String?
    /// The Spotify URI for the track.
    public var uri: SpotifyURI?
}

public struct RestrictionsJSON: ModelJSON, Hashable {
    /// The reason why the track is not available
    public var reason: String?
}
