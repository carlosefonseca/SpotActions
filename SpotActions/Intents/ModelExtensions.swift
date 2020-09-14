//
// ModelExtensions.swift
//

import Foundation
import CEFSpotifyCore

extension INUser {
    convenience init(from json: UserJSON) {
        self.init(identifier: json.id, display: json.display_name!)
        email = json.email
        country = json.country
        product = json.product
        uri = json.uri
    }
}

extension INArtist {
    convenience init(from json: ArtistJSON) {
        self.init(identifier: json.id, display: json.name!)
        self.uri = json.uri
    }
}

extension INPlaylist {
    convenience init(from json: PlaylistJSON) {
        self.init(identifier: json.id, display: json.name!)
        self.uri = json.uri
    }
}

extension INTrack {
    convenience init(from json: TrackJSON) {
        self.init(identifier: json.id, display: "\(json.name!) - \(json.artists!.compactMap { $0.name }.joined(separator: ", "))")
        self.trackName = json.name!
        self.artists = json.artists?.compactMap { INArtist(from: $0) } ?? []
        self.durationMs = (json.duration_ms ?? -1) as NSNumber
        self.uri = json.uri!
    }
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
