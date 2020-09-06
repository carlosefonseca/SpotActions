//
// GetPlaylistTracksHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

class GetPlaylistTracksHandler: NSObject, GetPlaylistTracksIntentHandling {

    let auth: SpotifyAuthManager
    let userManager: UserManager
    let playlistsManager: PlaylistsManager

    var bag = Set<AnyCancellable>()

    init(auth: SpotifyAuthManager, userManager: UserManager, playlistsManager: PlaylistsManager) {
        self.auth = auth
        self.userManager = userManager
        self.playlistsManager = playlistsManager
    }

    func handle(intent: GetPlaylistTracksIntent, completion: @escaping (GetPlaylistTracksIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        switch intent.option {
        case .recentTracks:

            playlistsManager.getRecentlyPlayed()
                .sink(receiveCompletion: { receiveCompletion in
                    if case .failure(let error) = receiveCompletion {
                        completion(.failure(error: error.localizedDescription))
                    }
                }, receiveValue: { tracks in
                    completion(.success(result: tracks.map { Track(from: $0) }))
                }).store(in: &bag)


        case .allTracks:

            guard let playlist = intent.playlist else {
                completion(.failure(error: "Parameter 'playlist' is empty!"))
                return
            }

            playlistsManager.getAllPlaylistTracks(playlistId: playlist.identifier!)
                .sink(receiveCompletion: { receiveCompletion in
                    if case .failure(let error) = receiveCompletion {
                        completion(.failure(error: error.localizedDescription))
                    }
                }, receiveValue: { tracks in
                    completion(.success(result: tracks.map { Track(from: $0) }))
                }).store(in: &bag)


        case .unknown:
            // TODO
            break
        }

    }

    func resolvePlaylist(for intent: GetPlaylistTracksIntent, with completion: @escaping (PlaylistResolutionResult) -> Void) {
        guard let playlist = intent.playlist else {
            completion(PlaylistResolutionResult.unsupported())
            return
        }
        completion(PlaylistResolutionResult.success(with: playlist))
    }

    func providePlaylistOptionsCollection(for intent: GetPlaylistTracksIntent, with completion: @escaping (INObjectCollection<Playlist>?, Error?) -> Void) {
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
