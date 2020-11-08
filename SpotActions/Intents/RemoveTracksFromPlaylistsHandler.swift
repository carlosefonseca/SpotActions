//
// RemoveTracksFromPlaylistsHandler.swift
//

import Foundation
import Intents
import Combine
import CEFSpotifyCore

class RemoveTracksFromPlaylistsHandler : NSObject, RemoveTracksFromPlaylistsIntentHandling {

    let auth: SpotifyAuthManager
    let playlistsManager: PlaylistsManager

    var bag = Set<AnyCancellable>()

    init(auth: SpotifyAuthManager, playlistsManager: PlaylistsManager) {
        self.auth = auth
        self.playlistsManager = playlistsManager
    }


    func handle(intent: RemoveTracksFromPlaylistsIntent, completion: @escaping (RemoveTracksFromPlaylistsIntentResponse) -> Void) {
        
    }

    func providePlaylistsOptionsCollection(for intent: RemoveTracksFromPlaylistsIntent, with completion: @escaping (INObjectCollection<INPlaylist>?, Error?) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(nil, "Not logged in!")
            return
        }

        playlistsManager.getAllUserPlaylists()
//            .filter {
//                $0.filter { $0. }
//            }
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
