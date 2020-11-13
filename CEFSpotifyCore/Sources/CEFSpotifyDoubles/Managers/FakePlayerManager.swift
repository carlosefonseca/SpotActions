//
// File.swift
//

import Foundation
import CEFSpotifyCore
import Combine

public class FakePlayerManager: PlayerManager {
    public init() {}

    public func getRecentlyPlayed() -> AnyPublisher<[TrackJSON], PlayerError> {
        return Fail(error: PlayerError.missingData(message: "TODO!!")).eraseToAnyPublisher()
    }

    public func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, PlayerError> {
        return Fail(error: PlayerError.missingData(message: "TODO!!")).eraseToAnyPublisher()
    }
}
