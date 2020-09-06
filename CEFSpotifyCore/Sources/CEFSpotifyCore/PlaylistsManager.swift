//
//  PlaylistsManagerImplementation.swift
//

import Foundation
import Combine

public protocol PlaylistsManager {
    var publisher: AnyPublisher<[PlaylistJSON], Never> { get }
    func getUserPlaylistsEach() -> AnyPublisher<[PlaylistJSON], Error>
}

public class PlaylistsManagerImplementation: PlaylistsManager {
    @Published var playlists: [PlaylistJSON] = []
    var next: URL?

    public var publisher: AnyPublisher<[PlaylistJSON], Never> {
        $playlists.removeDuplicates().eraseToAnyPublisher()
    }

    let auth: SpotifyAuthManager
    let gateway: SpotifyPlaylistsGateway

    public init(auth: SpotifyAuthManager, gateway: SpotifyPlaylistsGateway) {
        self.auth = auth
        self.gateway = gateway
    }

    public func getUserPlaylistsEach() -> AnyPublisher<[PlaylistJSON], Error> {
        let x = self.gateway.listUserPlaylists(limit: 50, offset: 0)
        return x.map { (data: PagedPlaylistsJSON) -> [PlaylistJSON] in
            self.playlists = data.items ?? []
            if let nextStr = data.next, let nextURL = URL(string: nextStr) {
                self.next = nextURL
            } else {
                self.next = nil
            }
            return data.items ?? []
        }.eraseToAnyPublisher()
    }
}
