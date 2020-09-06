//
// SaveTracksOnPlaylistHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

class SaveTracksOnPlaylistHandler: NSObject, SaveTracksOnPlaylistIntentHandling {

    let auth: SpotifyAuthManager
    let playlistsManager: PlaylistsManager

    var bag = Set<AnyCancellable>()

    init(auth: SpotifyAuthManager, playlistsManager: PlaylistsManager) {
        self.auth = auth
        self.playlistsManager = playlistsManager
    }

    func handle(intent: SaveTracksOnPlaylistIntent, completion: @escaping (SaveTracksOnPlaylistIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        guard let tracks = intent.tracks else {
            completion(.failure(error: "No tracks!"))
            return
        }

        guard let playlist = intent.playlist?.identifier else {
            completion(.failure(error: "No Playlist!"))
            return
        }

        let trackUris = tracks.compactMap { $0.uri }

        do {
            try playlistsManager.save(tracks: trackUris, on: playlist)
                .sink(receiveCompletion: { receiveCompletion in
                    if case .failure(let error) = receiveCompletion {
                        completion(.failure(error: error.localizedDescription))
                    } else {
                        completion(.success(tracks: tracks))
                    }
                }, receiveValue: { _ in
            }).store(in: &bag)
        } catch {
            completion(.failure(error: error.localizedDescription))
        }
    }

    func resolvePlaylist(for intent: SaveTracksOnPlaylistIntent, with completion: @escaping (PlaylistResolutionResult) -> Void) {
        guard let playlist = intent.playlist else {
            completion(PlaylistResolutionResult.unsupported())
            return
        }
        completion(PlaylistResolutionResult.success(with: playlist))
    }

    func providePlaylistOptionsCollection(for intent: SaveTracksOnPlaylistIntent, with completion: @escaping (INObjectCollection<Playlist>?, Error?) -> Void) {
        playlistsManager.getUserPlaylistsEach()
            .sink(
                receiveCompletion: { receiveCompletion in
                    if case .failure(let error) = receiveCompletion {
                        completion(nil, error)
                    }
                },
                receiveValue: { value in
                    completion(INObjectCollection(items: value.map { Playlist(from: $0) }), nil)
                }
            ).store(in: &bag)
    }
}
