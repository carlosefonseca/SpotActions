//
//  PlaylistsManagerImplementation.swift
//

import Foundation
import Combine

public protocol PlaylistsManager {
    var publisher: AnyPublisher<[PlaylistJSON], Never> { get }
    func getUserPlaylistsEach() -> AnyPublisher<[PlaylistJSON], Error>
    func getAllPlaylistTracks(playlistId: String) -> AnyPublisher<[TrackJSON], PlaylistsManagerError>
    func getRecentlyPlayed() -> AnyPublisher<[TrackJSON], PlaylistsManagerError>
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
        return self.gateway.getUserPlaylists(limit: 50, offset: 0).map { (data: PagedPlaylistsJSON) -> [PlaylistJSON] in
            self.playlists = data.items ?? []
            if let nextStr = data.next, let nextURL = URL(string: nextStr) {
                self.next = nextURL
            } else {
                self.next = nil
            }
            return data.items ?? []
        }.eraseToAnyPublisher()
    }

    public func getAllPlaylistTracks(playlistId: String) -> AnyPublisher<[TrackJSON], PlaylistsManagerError> {
        Deferred { () -> AnyPublisher<[TrackJSON], PlaylistsManagerError> in
            var bag = Set<AnyCancellable>()

            // Holds the current combination of values
            let subject = CurrentValueSubject<PagedTracksJSON?, PlaylistsManagerError>(nil)

            // When the current value changes, checks if there are more pages to load and loads the next page
            subject
                .compactMap { $0 }
                .print("getAllPlaylistTracks.xx0")
                .prefix(while: { page in page.next != nil })
                .print("getAllPlaylistTracks.xx1")
                .flatMap { page in
                    self.gateway.getNextPlaylistTracks(next: URL(string: page.next!)!)
                        .mapError { PlaylistsManagerError.requestError(error: $0) }
                        .map { newPage in
                            PagedTracksJSON(href: nil,
                                            items: page.items! + newPage.items!,
                                            limit: newPage.limit,
                                            next: newPage.next,
                                            offset: newPage.offset,
                                            previous: nil,
                                            total: newPage.total)
                        }
                }.sink { completion in
                    // Emits error
                    if case .failure = completion {
                        subject.send(completion: completion)
                    }
                } receiveValue: { page in
                    subject.send(page)
                }.store(in: &bag)

            // Initial request for the first page
            self.getPlaylistTracks(playlistId: playlistId, offset: 0)
                .mapError { PlaylistsManagerError.requestError(error: $0) }
                .print("getAllPlaylistTracks.FIRST1")
                .sink { completion in
                    // Emits error
                    if case .failure = completion {
                        subject.send(completion: completion)
                    }
                } receiveValue: { page in
                    print("getAllPlaylistTracks.FIRST2 subject playlist tracks setting on subject \(page)")
                    subject.send(page)
                }.store(in: &bag)

            // Waits until all pages have been loaded and outputs the track list
            return subject
                .compactMap { $0 }
                .print("getAllPlaylistTracks.x")
                .first { (page) -> Bool in page.next == nil }
                .map { $0.items!.map { $0.track! } }
                .print("getAllPlaylistTracks.Out")
                .handleEvents(
                    receiveOutput: { value in print("getAllPlaylistTracks.Out value \(value)") },
                    receiveCompletion: {
                        // Clear the other cancelables
                        print("getAllPlaylistTracks. completion removeAll \($0)")
                        bag.removeAll()
                    },
                    receiveCancel: {
                        // Clear the other cancelables
                        print("getAllPlaylistTracks. cancel removeAll")
                        bag.removeAll()
                    })
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    public func getPlaylistTracks(playlistId: String, offset: Int) -> AnyPublisher<PagedTracksJSON, Error> {
        return self.gateway.getPlaylistTracks(playlistId: playlistId, offset: offset)
    }

    public func getRecentlyPlayed() -> AnyPublisher<[TrackJSON], PlaylistsManagerError> {
        gateway.getRecentlyPlayed()
            .mapError { PlaylistsManagerError.requestError(error: $0) }
            .map { $0.items!.map { $0.track! } }
            .eraseToAnyPublisher()
    }


}

public enum PlaylistsManagerError: Error {
    case missingData(message: String)
    case requestError(error: Error)
}
