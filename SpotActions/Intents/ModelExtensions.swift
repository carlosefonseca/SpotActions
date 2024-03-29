//
// ModelExtensions.swift
//

import Foundation
import CEFSpotifyCore
import Intents

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
    public var id: SpotifyID { identifier! }
    public var totalTracks: Int? { self.trackCount?.intValue }
    convenience init(from json: PlaylistJSON) {
        self.init(identifier: json.id, display: json.name!)
        self.uri = json.uri
        if let image = json.images?.first, let imageUrl = URL(string: image.url) {
            self.imageUrl = imageUrl
            self.imageWidth = NSNumber(value: image.width ?? -1)
            self.imageHeight = NSNumber(value: image.height ?? -1)
        }
    }
}

extension INTrack: Track {
    public var albumArtWidth: Int? { self.albumArtW?.intValue }
    public var albumArtHeight: Int? { self.albumArtH?.intValue }

    convenience init(from json: Track) {
        self.init(identifier: json.id, display: "\(json.title!) - \(json.artistNames.joined(separator: ", "))")
        self.title = json.title

        self.artists = zip(json.artistIds, json.artistNames)
            .map { id, name in INArtist(identifier: id, display: name) }

        self.uri = json.uri!
        self.linkedTrackId = json.linkedTrackId

        self.externalIds = json.externalIdsStr?.compactMap { str in
            let split = str.split(separator: ":")
            guard split.count >= 2 else { return nil }
            return INExternalId(key: String(split.first!), value: String(split.last!))
        }

        if let millis = json.durationMs {
            self.durationMillis = millis as NSNumber
            self.duration = NSNumber(value: millis) // "\(millis / 1000 / 60):\(millis % 60)"
        }

        self.albumName = json.albumName

        if let imageUrl = json.albumArtUrl {
            self.albumArtUrl = imageUrl
            if let width = json.albumArtWidth, let height = json.albumArtHeight {
                self.albumArtW = NSNumber(value: width)
                self.albumArtH = NSNumber(value: height)
            }
        }
    }

//    convenience init(from json: TrackJSON) {
//        self.init(identifier: json.id, display: concatTrackNameArtists(name: json.name!, artists: json.artists!))
//        self.title = json.name!
//        self.artists = json.artists?.compactMap { INArtist(from: $0) } ?? []
//        self.uri = json.uri!
//        self.linkedTrackId = json.linkedFrom?.id
//
//        self.externalIds = json.externalIds?.map { key, value in
//            INExternalId(key: key, value: value)
//        }
//
//        if let millis = json.durationMs {
//            self.durationMillis = millis as NSNumber
//            self.duration = "\(millis / 1000 / 60):\(millis % 60)"
//        }
//
//        if let image = json.images?.first, let imageUrlStr = image.url, let imageUrl = URL(string: imageUrlStr) {
//            self.imageUrl = imageUrl
//            self.imageWidth = NSNumber(value: image.width ?? -1)
//            self.imageHeight = NSNumber(value: image.height ?? -1)
//
//            self.displayImage = INImage(url: imageUrl,
//                                        width: image.width ?? -1,
//                                        height: image.height ?? -1)
//        }
//    }

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

    public var artistIds: [SpotifyID] {
        artists?.map { $0.id } ?? []
    }

    public var artistNames: [SpotifyID] {
        artists?.map { $0.name ?? "" } ?? []
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

extension INImage {
    convenience init?(from imageJson: ImageJSON) {
        guard
            let url = URL(string: imageJson.url)
        else { return nil }

        if let w = imageJson.width, let h = imageJson.height {
            self.init(url: url, width: Double(w), height: Double(h))
        }
        self.init(url: url)
    }
}
