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

        let regex: NSRegularExpression?
        do {
            if let filter = intent.filter {
                regex = try NSRegularExpression(pattern: filter, options: .caseInsensitive)
            } else {
                regex = nil
            }
        } catch {
            completion(.failure(error: "Failed to parse the filter regular expression!"))
            return
        }

        let fetchPublisher: AnyPublisher<[PlaylistJSON], Error>

        switch intent.fetchPageMode {
        case .unknown:
            completion(.failure(error: "Fetch page option not selected!"))
            return
        case .first:
            fetchPublisher = playlistsManager.getFirstPageUserPlaylists()
        case .all:
            fetchPublisher = playlistsManager.getAllUserPlaylists()
        }

        fetchPublisher.map {
            let items = (regex != nil) ? $0.filter { $0.name?.contains(regex: regex!) ?? false } : $0
            return items.compactMap { (pJSON) -> INPlaylist in
                INPlaylist(identifier: pJSON.id!, display: pJSON.name!)
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
