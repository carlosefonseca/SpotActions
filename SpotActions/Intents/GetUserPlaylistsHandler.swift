//
//  GetUserPlaylistsIntent.swift
//  SpotActions
//
//  Created by carlos.fonseca on 23/08/2020.
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

        playlistsManager.getUserPlaylistsEach()
            .print()
            .map {
                $0.compactMap { (pJSON) -> Playlist in
                    let p = Playlist(identifier: pJSON.id!, display: pJSON.name!)
                    p.totalTracks = pJSON.tracks!.total! as NSNumber
//                    p.tracks = pJSON.tracks!.items?.compactMap { (tJSON) -> Track in
//                        Track(identifier: tJSON.id, display: tJSON.name!)
//                    }
                    return p
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

extension Artist {
    convenience init(from json: ArtistJSON) {
        self.init(identifier: json.id, display: json.name!)
    }
}

extension Playlist {
    convenience init(from json: PlaylistJSON) {
        self.init(identifier: json.id, display: json.name!)
    }
}

extension Track {
    convenience init(from json: TrackJSON) {
        self.init(identifier: json.id, display: "\(json.name!) - \(json.artists!.compactMap { $0.name }.joined(separator: ", "))")
        self.trackName = json.name!
        self.artists = json.artists?.compactMap { Artist(from: $0) } ?? []
        self.durationMs = (json.duration_ms ?? -1) as NSNumber
    }
}
