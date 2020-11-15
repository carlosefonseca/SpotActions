//
// WatchScreenModel.swift
//

import Foundation

struct ScreenModel: Codable {
    var login: LoginModel?
    var playback: PlaybackViewModel?
}

struct PlaybackViewModel: Codable {
    var track: TrackViewModel
    var isPlaying: Bool
}

struct TrackViewModel: Codable {
    var title: String
    var artist: String
    var imageUrl: URL?
}

struct LoginModel: Codable {
    var username: String
}
