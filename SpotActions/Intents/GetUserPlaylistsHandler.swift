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
            if let filter = intent.filter, !filter.isEmpty {
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

        fetchPublisher
            .map {
                var items = (regex != nil) ? $0.filter { $0.name?.contains(regex: regex!) ?? false } : $0

                if var ownerName = intent.owner, !ownerName.isEmpty {
                    if ownerName.starts(with: "!") {
                        ownerName = String(ownerName.dropFirst())
                        items = items.filter { $0.owner?.id != ownerName }
                    } else {
                        items = items.filter { $0.owner?.id == ownerName }
                    }
                }

                return items.compactMap { (pJSON) -> INPlaylist in
                    var inImage: INImage?
                    if let img = pJSON.images?.min(by: { (img1, img2) -> Bool in img1.width ?? 0 < img2.width ?? 0 }) {
                        inImage = INImage(from: img)
                    }
                    return INPlaylist(identifier: pJSON.id, display: pJSON.name!, subtitle: pJSON.description, image: inImage)
//                    return INPlaylist(identifier: pJSON.id, display: pJSON.name!)
                }
            }
            .print("GetUserPlaylistsHandler")
            .sink { it in
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
