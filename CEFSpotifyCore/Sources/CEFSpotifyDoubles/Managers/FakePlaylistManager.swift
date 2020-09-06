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
}
