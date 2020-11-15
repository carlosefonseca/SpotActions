//
// WatchMessageWrapper.swift
//

import Foundation

class WatchMessageWrapper {

    enum Keys: String {
        case trackName = "tN"
        case artists = "tA"
        case albumUrl = "tI"
        case isPlaying = "p"
    }

    var message = [String: Any]()

    var trackName: String? {
        get { message[Keys.trackName.rawValue] as? String }
        set { message[Keys.trackName.rawValue] = newValue }
    }

    var trackArtistName: String? {
        get { message[Keys.artists.rawValue] as? String }
        set { message[Keys.artists.rawValue] = newValue }
    }

    var trackAlbumUrl: String? {
        get { message[Keys.albumUrl.rawValue] as? String }
        set { message[Keys.albumUrl.rawValue] = newValue }
    }

    var isPlaying: Bool? {
        get { message[Keys.isPlaying.rawValue] as? Bool }
        set { message[Keys.isPlaying.rawValue] = newValue }
    }
}
