//
// ModelExtensions.swift
//

import Foundation
import CEFSpotifyCore

extension INUser: User {
    convenience init(from json: UserJSON) {
        self.init(identifier: json.id, display: json.displayName!)
        email = json.email
        country = json.country
        product = json.product
        uri = json.uri
    }

    public var displayName: String? { self.displayString }
}

extension INArtist: Artist {
    convenience init(from json: ArtistJSON) {
        self.init(identifier: json.id, display: json.name!)
        self.uri = json.uri
    }

    public var name: String? { displayString }
    public var id: SpotifyID { identifier! }
}

extension INPlaylist: Playlist {
    public var totalTracks: Int? { self.trackCount?.intValue }
    convenience init(from json: PlaylistJSON) {
        self.init(identifier: json.id, display: json.name!)
        self.uri = json.uri
    }
}

extension INTrack: Track {
    convenience init(from json: TrackJSON) {
        self.init(identifier: json.id, display: concatTrackNameArtists(name: json.name!, artists: json.artists!))
        self.title = json.name!
        self.artists = json.artists?.compactMap { INArtist(from: $0) } ?? []
        self.uri = json.uri!
        self.linkedTrackId = json.linkedFrom?.id

        self.externalIds = json.externalIds?.map { key, value in
            INExternalId(key: key, value: value)
        }

        if let millis = json.durationMs {
            self.durationMillis = millis as NSNumber
            self.duration = "\(millis / 1000 / 60):\(millis % 60)"
        }
    }

    convenience init(artists: [INArtist], externalIds: [SpotActions.INExternalId]?, id: String, linkedTrackId: String?, name: String) {
        self.init(identifier: id, display: concatTrackNameArtists(name: name, artists: artists))
        self.title = name
        self.artists = artists
        self.uri = "spotify:track:\(id)"
        self.externalIds = externalIds
        self.linkedTrackId = linkedTrackId
    }

    public var id: SpotifyID { identifier! }

    public var durationMs: Int? {
        self.durationMillis?.intValue
    }

    public var externalIdsStr: [String]? {
        externalIds?.compactMap { $0.identifier }
    }
}

func concatTrackNameArtists<A: Artist>(name: String, artists: [A]) -> String {
    "\(name) - \(artists.compactMap { $0.name }.joined(separator: ", "))"
}

extension INCurrentlyPlaying {
    convenience init?(trackFrom json: CurrentlyPlayingJSON) {
        guard let trackJson = json.item else {
            return nil
        }
        let track = INTrack(from: trackJson)
        self.init(identifier: nil, display: track.displayString)
        self.track = track
    }

    convenience init(from json: CurrentlyPlayingJSON, playlist playlistJSON: PlaylistJSON) {
        let track = (json.item != nil) ? INTrack(from: json.item!) : nil
        let playlist = INPlaylist(from: playlistJSON)
        let trackName = track?.displayString
        let playlistName = playlist.displayString
        let name = [trackName, playlistName].compactMap { $0 }.joined(separator: " on ")
        self.init(identifier: nil, display: name)
        self.track = track
        self.playlist = playlist
    }
}

extension INExternalId {
    convenience init(key: String, value: String) {
        self.init(identifier: "\(key):\(value)", display: "\(key):\(value)")
        self.key = key
        self.value = value
    }

    class func from(_ original: [String: String]) -> [INExternalId] {
        original.map { (key, value) -> INExternalId in
            INExternalId(key: key, value: value)
        }
    }
}
