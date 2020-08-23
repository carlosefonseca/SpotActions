//
//  PlaylistsManagerImplementation.swift
//

import Foundation
import Combine

public protocol PlaylistsManager {
//    func getUserPlaylists() -> AnyPublisher<[PlaylistJSON], SpotifyWebApiError>
    func getUserPlaylistsEach() -> Future<PagedPlaylistsJSON, SpotifyRequestError>
}

public class PlaylistsManagerImplementation: PlaylistsManager {
    let auth: SpotifyAuthManager
    let gateway: SpotifyPlaylistsGateway

    public init(auth: SpotifyAuthManager, gateway: SpotifyPlaylistsGateway) {
        self.auth = auth
        self.gateway = gateway

//        self.auth.statePublisher
//            .receive(on: RunLoop.main)
//            .map { authState -> Bool in
//                if case .loggedIn = authState { return true }
//                return false
//            }.flatMap { loggedIn -> AnyPublisher<[PlaylistJSON], SpotifyWebApiError> in
//                if loggedIn {
//                    return getUserPlaylists()
//                } else {
//                    clearCache()
//                    return Empty<[PlaylistJSON], SpotifyWebApiError>(completeImmediately: false)
//                }
//            }.sink { _ in }
    }

//    public func getUserPlaylists() -> AnyPublisher<[PlaylistJSON], SpotifyWebApiError> {
    // return AnyPublisher(
//        getUserPlaylistsEach().
//
//
//        self.gateway.listUserPlaylists(limit: 50, offset: 0) { result in
//            switch result {
//            case .success(let response):
//                print("\(response.href) \(response.offset)...\(response.offset + response.limit) [total : \(response.total)]")
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }

    public func getUserPlaylistsEach() -> Future<PagedPlaylistsJSON, SpotifyRequestError> {
        return Future { promise in
            self.gateway.listUserPlaylists(limit: 50, offset: 0) { result in
                switch result {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    print(error)
                    promise(.failure(error))
                }
            }
        }
    }
}
