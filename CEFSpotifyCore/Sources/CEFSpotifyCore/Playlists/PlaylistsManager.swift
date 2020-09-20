//
//  PlaylistsManagerImplementation.swift
//

import Foundation
import Combine

public protocol PlaylistsManager {
    var publisher: AnyPublisher<[PlaylistJSON], Never> { get }
    func getAllUserPlaylists() -> AnyPublisher<[PlaylistJSON], Error>
    func getFirstPageUserPlaylists() -> AnyPublisher<[PlaylistJSON], Error>
    func getAllPlaylistTracks(playlistId: String) -> AnyPublisher<[TrackJSON], PlaylistsManagerError>
    func getPlaylist(playlistId: SpotifyID) -> AnyPublisher<PlaylistJSON, PlaylistsManagerError>
    func save(tracks: [TrackJSON], on playlist: PlaylistJSON) throws -> AnyPublisher<Never, PlaylistsManagerError>
    func save(tracks: [String], on playlistId: String) throws -> AnyPublisher<Never, PlaylistsManagerError>
}

public class PlaylistsManagerImplementation: PlaylistsManager {
    @Published var playlists: [PlaylistJSON] = []
    var next: URL?

    public var publisher: AnyPublisher<[PlaylistJSON], Never> {
        $playlists.removeDuplicates().eraseToAnyPublisher()
    }

    let auth: SpotifyAuthManager
    let gateway: SpotifyPlaylistsGateway
    let maxTracksToSaveAtOnce: Int

    public init(auth: SpotifyAuthManager, gateway: SpotifyPlaylistsGateway, maxTracksToSaveAtOnce: Int = 100) {
        self.auth = auth
        self.gateway = gateway
        self.maxTracksToSaveAtOnce = maxTracksToSaveAtOnce
    }

    public func getAllUserPlaylists() -> AnyPublisher<[PlaylistJSON], Error> {
        let x: AnyPublisher<PagedPlaylistsJSON, Error> = self.gateway.getUserPlaylists(limit: 50, offset: 0)
        let y = self.loadNext(x: x) { self.gateway.getNextUserPlaylists(next: $0) }.print()
        return y.map { page in page.items! }
            .reduce([PlaylistJSON]()) { accumulator, items -> [PlaylistJSON] in accumulator + items }
            .eraseToAnyPublisher()
    }

    public func getFirstPageUserPlaylists() -> AnyPublisher<[PlaylistJSON], Error> {
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
                .prefix(while: { page in page.next != nil })
                .eraseToAnyPublisher()
                .flatMap { page in self.fetchAndMerge(page) }
                .eraseToAnyPublisher()
                .sink { completion in
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
                .sink { completion in
                    // Emits error
                    if case .failure = completion {
                        subject.send(completion: completion)
                    }
                } receiveValue: { page in
                    subject.send(page)
                }.store(in: &bag)

            // Waits until all pages have been loaded and outputs the track list
            return subject
                .compactMap { $0 }
                .first { (page) -> Bool in page.next == nil }
                .map { $0.items!.map { $0.track! } }
                .handleEvents(
                    receiveCompletion: { _ in
                        // Clear the other cancelables
                        bag.removeAll()
                    },
                    receiveCancel: {
                        // Clear the other cancelables
                        bag.removeAll()
                    }
                )
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    public func getPlaylistTracks(playlistId: String, offset: Int) -> AnyPublisher<PagedTracksJSON, Error> {
        return self.gateway.getPlaylistTracks(playlistId: playlistId, offset: offset)
    }

    public func save(tracks: [TrackJSON], on playlist: PlaylistJSON) throws -> AnyPublisher<Never, PlaylistsManagerError> {
        self.save(tracks: tracks.compactMap { $0.id }, on: playlist.id!)
    }

    public func save(tracks: [String], on playlist: String) -> AnyPublisher<Never, PlaylistsManagerError> {
        return Deferred<AnyPublisher<Never, PlaylistsManagerError>> {
            do {
                if tracks.count > self.maxTracksToSaveAtOnce {
                    let chunks = tracks.chunked(into: self.maxTracksToSaveAtOnce)

                    let publishers = chunks.enumerated().map { (index, tracks) -> AnyPublisher<Never, PlaylistsManagerError> in
                        do {
                            if index == 0 {
                                return try self.gateway.replace(tracks: tracks, on: playlist)
                                    .print("save.replace \(index)")
                                    .mapError { PlaylistsManagerError.requestError(error: $0) }
                                    .ignoreOutput()
                                    .eraseToAnyPublisher()
                            } else {
                                return try self.gateway.add(tracks: tracks, to: playlist, at: nil)
                                    .print("save.append \(index)")
                                    .mapError { PlaylistsManagerError.requestError(error: $0) }
                                    .ignoreOutput()
                                    .eraseToAnyPublisher()
                            }
                        } catch {
                            return Fail(error: PlaylistsManagerError.requestError(error: error)).eraseToAnyPublisher()
                        }
                    }

                    let x: AnyPublisher<Never, PlaylistsManagerError> = Publishers.Sequence(sequence: publishers)
                        .flatMap { $0 }
                        .eraseToAnyPublisher()
                    return x
                } else {
                    let x: AnyPublisher<Never, PlaylistsManagerError> = try self.gateway.replace(tracks: tracks, on: playlist)
                        .print("save.replace once")
                        .mapError { PlaylistsManagerError.requestError(error: $0) }
                        .eraseToAnyPublisher()
                    return x
                }
            } catch {
                return Fail(error: PlaylistsManagerError.requestError(error: error)).eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }

    public func getPlaylist(playlistId: SpotifyID) -> AnyPublisher<PlaylistJSON, PlaylistsManagerError> {
        return self.gateway.getPlaylist(playlistId: playlistId)
            .mapError { PlaylistsManagerError.requestError(error: $0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func fetchAndMerge(_ page: PagedTracksJSON) -> AnyPublisher<PagedTracksJSON, PlaylistsManagerError> {
        return self.gateway.getNextPlaylistTracks(next: URL(string: page.next!)!)
            .map { newPage -> PagedTracksJSON in
                PagedTracksJSON(href: nil,
                                items: page.items! + newPage.items!,
                                limit: newPage.limit,
                                next: newPage.next,
                                offset: newPage.offset,
                                previous: nil,
                                total: newPage.total)
            }
            .mapError { PlaylistsManagerError.requestError(error: $0) }
            .eraseToAnyPublisher()
    }

    private func loadNext<T>(x: AnyPublisher<PagingJSON<T>, Error>, fetch: @escaping (URL) -> AnyPublisher<PagingJSON<T>, Error>) -> AnyPublisher<PagingJSON<T>, Error> where T: Codable, T: Equatable {
        return x.flatMap { (page) -> AnyPublisher<PagingJSON<T>, Error> in
            if let next = page.next {
                let y: AnyPublisher<PagingJSON<T>, Error> = fetch(URL(string: next)!)
                return Just(page).setFailureType(to: Error.self).append(
                    self.loadNext(x: y, fetch: fetch)
                ).eraseToAnyPublisher()
            } else {
                return Just(page).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }
}

public enum PlaylistsManagerError: Error, LocalizedError {
    case missingData(message: String)
    case requestError(error: Error)

    public var errorDescription: String? {
        switch self {
        case .missingData(let message):
            return message
        case .requestError(let error):
            return error.localizedDescription
        }
    }
}
