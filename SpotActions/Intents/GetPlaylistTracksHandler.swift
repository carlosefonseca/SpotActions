//
// GetPlaylistTracksHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

class GetPlaylistTracksHandler: NSObject, GetPlaylistTracksIntentHandling {

    let auth: SpotifyAuthManager
    let playlistsManager: PlaylistsManager
    let playerManager: PlayerManager

    var bag = Set<AnyCancellable>()

    init(auth: SpotifyAuthManager, playlistsManager: PlaylistsManager, playerManager: PlayerManager) {
        self.auth = auth
        self.playlistsManager = playlistsManager
        self.playerManager = playerManager
    }

    func handle(intent: GetPlaylistTracksIntent, completion: @escaping (GetPlaylistTracksIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        var publisher: AnyPublisher<[INTrack], ErrorMessage>
        switch intent.option {
        case .recentTracks:

            publisher = playerManager.getRecentlyPlayed()
                .map { tracks in tracks.map { INTrack(from: $0) } }
                .mapError { error in error.localizedDescription }
                .eraseToAnyPublisher()

        case .allTracks:

            guard let playlist = intent.playlist else {
                completion(.failure(error: "Parameter 'playlist' is empty!"))
                return
            }

            publisher = playlistsManager.getAllPlaylistTracks(playlistId: playlist.identifier!)
                .map { tracks in tracks.map { INTrack(from: $0) } }
                .mapError { error in error.localizedDescription }
                .eraseToAnyPublisher()

        case .unknown:
            completion(.failure(error: "Option Unknown"))
            return
        }

        publisher
            .sink(receiveCompletion: { receiveCompletion in
                if case .failure(let error) = receiveCompletion {
                    completion(.failure(error: error))
                }
            }, receiveValue: { tracks in
                completion(.success(result: tracks))
            }).store(in: &bag)
    }

    func resolvePlaylist(for intent: GetPlaylistTracksIntent, with completion: @escaping (INPlaylistResolutionResult) -> Void) {
        guard let playlist = intent.playlist else {
            completion(INPlaylistResolutionResult.unsupported())
            return
        }
        completion(INPlaylistResolutionResult.success(with: playlist))
    }

    func providePlaylistOptionsCollection(for intent: GetPlaylistTracksIntent, with completion: @escaping (INObjectCollection<INPlaylist>?, Error?) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(nil, "Not logged in!")
            return
        }

        playlistsManager.getFirstPageUserPlaylists()
            .sink(
                receiveCompletion: { receiveCompletion in
                    if case .failure(let error) = receiveCompletion {
                        completion(nil, error)
                    }
                },
                receiveValue: { value in
                    completion(INObjectCollection(items: value.map { INPlaylist(from: $0) }), nil)
                }
            ).store(in: &bag)
    }
}
