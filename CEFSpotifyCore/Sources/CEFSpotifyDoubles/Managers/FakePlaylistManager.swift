//
//  FakePlaylistsManager.swift
//

import Foundation
import Combine
import CEFSpotifyCore

public class FakePlaylistsManager: PlaylistsManager {

    @Published public var playlists = [PlaylistJSON]()

    public init() {}

    public var publisher: AnyPublisher<[PlaylistJSON], Never> {
        $playlists.eraseToAnyPublisher()
    }

    public func getUserPlaylistsEach() -> AnyPublisher<[PlaylistJSON], Error> {
        return $playlists.first().setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    public func getAllPlaylistTracks(playlistId: String) -> AnyPublisher<[TrackJSON], PlaylistsManagerError> {
        // TODO
        return Fail(error: PlaylistsManagerError.missingData(message: "TODO!!")).eraseToAnyPublisher()
    }

    public func getRecentlyPlayed() -> AnyPublisher<[TrackJSON], PlaylistsManagerError> {
        return Fail(error: PlaylistsManagerError.missingData(message: "TODO!!")).eraseToAnyPublisher()
    }
}
