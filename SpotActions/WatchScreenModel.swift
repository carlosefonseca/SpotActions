//
// WatchScreenModel.swift
//

import Foundation
import CEFSpotifyCore

struct ScreenModel: Codable {
    var login: LoginModel?
    var playback: PlaybackViewModel?
}

struct PlaybackViewModel: Codable, Equatable {
    var title: String?
    var artist: String?
    var imageUrl: String?
    var isPlaying: Bool = false
}

extension PlaybackViewModel {
    init(from data: CurrentlyPlayingJSON?) {
        if let track = data?.item {
            title = track.title ?? "!?"
            artist = track.artistNames.joined(separator: ", ")
            imageUrl = track.albumArtUrl?.absoluteString
        }
        isPlaying = data?.isPlaying ?? false
    }

    init(from message: [String: Any]) {
        title = message["t"] as? String
        artist = message["a"] as? String
        imageUrl = message["i"] as? String
        isPlaying = message["p"] as? Bool ?? false
    }
}

struct LoginModel: Codable {
    var username: String
}

extension PlaybackViewModel {
    func toDictionary() -> [String: Any] {
        [
            "_t": "PlaybackViewModel",
            "t": title as Any,
            "a": artist as Any,
            "i": imageUrl as Any,
            "p": isPlaying
        ]
    }
}
