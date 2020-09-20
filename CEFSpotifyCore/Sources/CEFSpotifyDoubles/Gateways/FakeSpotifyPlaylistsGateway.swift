//
// FakeSpotifyPlaylistsGateway.swift
//

import Foundation
import CEFSpotifyCore
import Combine

public class FakeSpotifyPlaylistsGateway: SpotifyPlaylistsGateway {

    // MOCK DATA TO OUTPUT
    public var userPlaylistsResponses = [Result<PagedPlaylistsJSON, Error>]()
    public var nextUserPlaylistsResponses = [Result<PagedPlaylistsJSON, Error>]()
    public var playlistTracksResponses = [Result<PagedTracksJSON, Error>]()
    public var nextPlaylistTracksResponses = [Result<PagedTracksJSON, Error>]()
    public var replaceResponses = [Error?]()
    public var addResponses = [Error?]()
    public var getPlaylistResponses = [Result<PlaylistJSON, Error>]()

    public enum Methods: Equatable {
        case getUserPlaylists(limit: Int, offset: Int)
        case getNextUserPlaylists(next: URL)
        case getPlaylistTracks(playlistId: String, offset: Int)
        case getNextPlaylistTracks(next: URL?)
        case getRecentlyPlayed
        case replace(tracks: [String], playlistId: String)
        case add(tracks: [SpotifyURI], playlistId: String, index: Int?)
        case getPlaylist(playlistId: SpotifyID)
    }

    public var calls = [Methods]()

    public init() {}

    public func getUserPlaylists(limit: Int, offset: Int) -> AnyPublisher<PagedPlaylistsJSON, Error> {
        Deferred {
            Future { promise in
                self.calls.append(.getUserPlaylists(limit: limit, offset: offset))
                promise(self.userPlaylistsResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func getNextUserPlaylists(next: URL) -> AnyPublisher<PagedPlaylistsJSON, Error> {
        Deferred {
            Future { promise in
                self.calls.append(.getNextUserPlaylists(next: next))
                promise(self.nextUserPlaylistsResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func getPlaylistTracks(playlistId: String, offset: Int) -> AnyPublisher<PagedTracksJSON, Error> {
        Deferred {
            Future { promise in
                self.calls.append(.getPlaylistTracks(playlistId: playlistId, offset: offset))
                promise(self.playlistTracksResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func getNextPlaylistTracks(next: URL) -> AnyPublisher<PagedTracksJSON, Error> {
        Deferred {
            Future { promise in
                self.calls.append(.getNextPlaylistTracks(next: next))
                promise(self.nextPlaylistTracksResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error> {
        Deferred {
            Future { promise in
                self.calls.append(.getRecentlyPlayed)
                promise(self.nextPlaylistTracksResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }

    public func replace(tracks: [String], on playlistId: String) throws -> AnyPublisher<Never, Error> {
        return Deferred<AnyPublisher<Never, Error>> {
            self.calls.append(.replace(tracks: tracks, playlistId: playlistId))
            let output: Error? = self.replaceResponses.removeFirst()
            return errorToPublisher(error: output, outputType: Never.self)
        }
        .eraseToAnyPublisher()
    }

    public func add(tracks: [SpotifyURI], to playlistId: String, at index: Int?) throws -> AnyPublisher<Never, Error> {
        return Deferred<AnyPublisher<Never, Error>> {
            self.calls.append(.add(tracks: tracks, playlistId: playlistId, index: index))
            let output: Error? = self.addResponses.removeFirst()
            return errorToPublisher(error: output, outputType: Never.self)

        }.eraseToAnyPublisher()
    }

    public func getPlaylist(playlistId: SpotifyID) -> AnyPublisher<PlaylistJSON, Error> {
        Deferred {
            Future { promise in
                self.calls.append(.getPlaylist(playlistId: playlistId))
                promise(self.getPlaylistResponses.removeFirst())
            }
        }.eraseToAnyPublisher()
    }
}
