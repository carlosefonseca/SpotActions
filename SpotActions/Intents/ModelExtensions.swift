//
// ModelExtensions.swift
//

import Foundation
import CEFSpotifyCore

extension User {
    convenience init(from json: UserJSON) {
        self.init(identifier: json.id, display: json.display_name!)
        email = json.email
        country = json.country
        product = json.product
        uri = json.uri
    }
}

extension Artist {
    convenience init(from json: ArtistJSON) {
        self.init(identifier: json.id, display: json.name!)
        self.uri = json.uri
    }
}

extension Playlist {
    convenience init(from json: PlaylistJSON) {
        self.init(identifier: json.id, display: json.name!)
        self.uri = json.uri
    }
}

extension Track {
    convenience init(from json: TrackJSON) {
        self.init(identifier: json.id, display: "\(json.name!) - \(json.artists!.compactMap { $0.name }.joined(separator: ", "))")
        self.trackName = json.name!
        self.artists = json.artists?.compactMap { Artist(from: $0) } ?? []
        self.durationMs = (json.duration_ms ?? -1) as NSNumber
        self.uri = json.uri!
    }
}

extension CurrentlyPlaying {
    convenience init?(trackFrom json: CurrentlyPlayingJSON) {
        guard let trackJson = json.item else {
            return nil
        }
        let track = Track(from: trackJson)
        self.init(identifier: nil, display: track.displayString)
        self.track = track
    }

    convenience init(from json: CurrentlyPlayingJSON, playlist playlistJSON: PlaylistJSON) {
        let track = (json.item != nil) ? Track(from: json.item!) : nil
        let playlist = Playlist(from: playlistJSON)
        let trackName = track?.displayString
        let playlistName = playlist.displayString
        let name = [trackName, playlistName].compactMap { $0 }.joined(separator: " on ")
        self.init(identifier: nil, display: name)
        self.track = track
        self.playlist = playlist
    }
}
