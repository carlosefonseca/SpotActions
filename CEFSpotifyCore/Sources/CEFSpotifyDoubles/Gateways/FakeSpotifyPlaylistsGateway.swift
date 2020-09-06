//
// FakeSpotifyPlaylistsGateway.swift
//

import Foundation
import CEFSpotifyCore
import Combine

public class FakeSpotifyPlaylistsGateway: SpotifyPlaylistsGateway {

    public var userPlaylistsResponses = [Result<PagedPlaylistsJSON, Error>]()
    public var playlistTracksResponses = [Result<PagedTracksJSON, Error>]()
    public var nextPlaylistTracksResponses = [Result<PagedTracksJSON, Error>]()

    public init() {}

    public func getUserPlaylists(limit: Int, offset: Int) -> AnyPublisher<PagedPlaylistsJSON, Error> {
        Deferred {
            Future { promise in
                promise(self.userPlaylistsResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func getPlaylistTracks(playlistId: String, offset: Int) -> AnyPublisher<PagedTracksJSON, Error> {
        Deferred {
            Future { promise in
                promise(self.playlistTracksResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func getNextPlaylistTracks(next: URL) -> AnyPublisher<PagedTracksJSON, Error> {
        Deferred {
            Future { promise in
                promise(self.nextPlaylistTracksResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error> {
        return Fail(error: PlaylistsManagerError.missingData(message: "TODO!!")).eraseToAnyPublisher()
    }

    public func save(tracks: [String], on playlistId: String) throws -> AnyPublisher<Never, Error> {
        return Fail(error: PlaylistsManagerError.missingData(message: "TODO!!")).eraseToAnyPublisher()
    }
}
