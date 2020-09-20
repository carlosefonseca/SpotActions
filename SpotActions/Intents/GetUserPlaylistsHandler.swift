//
//  GetUserPlaylistsIntent.swift
//  SpotActions
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

class GetUserPlaylistsHandler: NSObject, GetUserPlaylistsIntentHandling {

    let auth: SpotifyAuthManager
    let userManager: UserManager
    let playlistsManager: PlaylistsManager

    var bag = Set<AnyCancellable>()

    init(auth: SpotifyAuthManager, userManager: UserManager, playlistsManager: PlaylistsManager) {
        self.auth = auth
        self.userManager = userManager
        self.playlistsManager = playlistsManager
    }

    func handle(intent: GetUserPlaylistsIntent, completion: @escaping (GetUserPlaylistsIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        playlistsManager.getAllUserPlaylists()
            .print()
            .map {
                $0.compactMap { (pJSON) -> INPlaylist in
                    return INPlaylist(identifier: pJSON.id!, display: pJSON.name!)
                }
            }.sink { it in
                switch it {
                case .failure(let error):
                    completion(.failure(error: error.localizedDescription))
                case .finished:
                    break
                }
            } receiveValue: { playlists in
                completion(.success(result: playlists))
            }.store(in: &bag)
    }
}

