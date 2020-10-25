//
// GetPlayingPlaylistHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

enum GetPlayingPlaylistHandlerError: Error {
    case message(_ message: String)
}

class GetPlayingPlaylistHandler: NSObject, GetPlayingPlaylistIntentHandling {
    let auth: SpotifyAuthManager
    let playerManager: PlayerManager
    let playlistManager: PlaylistsManager

    var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, playerManager: PlayerManager, playlistManager: PlaylistsManager) {
        self.auth = auth
        self.playerManager = playerManager
        self.playlistManager = playlistManager
    }

    private func processForPlaylist() -> AnyPublisher<INPlaylist, GetPlayingPlaylistHandlerError> {
        playerManager.getCurrentlyPlaying()
            .mapError { GetPlayingPlaylistHandlerError.message($0.localizedDescription) }
            .flatMap { (playing: CurrentlyPlayingJSON?) -> AnyPublisher<INPlaylist, GetPlayingPlaylistHandlerError> in
                guard
                    let context = playing?.context,
                    context.type == "playlist",
                    let uri = context.uri,
                    uri.category == "playlist"
                else {
                    return Fail(error: GetPlayingPlaylistHandlerError.message("No playlist is playing")).eraseToAnyPublisher()
                }

                return self.playlistManager.getPlaylist(playlistId: uri.id)
                    .mapError { GetPlayingPlaylistHandlerError.message($0.localizedDescription) }
                    .map { playlist in INPlaylist(from: playlist) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func handle(intent: GetPlayingPlaylistIntent, completion: @escaping (GetPlayingPlaylistIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        processForPlaylist()
            .sink(
                receiveCompletion: { compl in
                    if case .failure(let error) = compl {
                        completion(.failure(error: error.localizedDescription))
                    }
                },
                receiveValue: { value in
                    completion(.success(result: value))
                }
            )
            .store(in: &bag)
    }
}
