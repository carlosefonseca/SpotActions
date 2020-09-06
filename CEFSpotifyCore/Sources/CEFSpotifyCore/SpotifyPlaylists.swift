//
//  SpotifyPlaylists.swift
//

import Foundation
import Combine

public extension SpotifyWebApi.Playlists {
    enum GetUserPlaylists {}
    enum GetPlaylistTracks {}

//    enum GetPlaylist {}
//    enum CreatePlaylist {}
//
//    enum GetItems {}
//    enum AddItems {}
//    enum RemoveItems {}
//    enum ReorderItems {}
//    enum ReplaceItems {}
}

extension SpotifyWebApi.Playlists.GetUserPlaylists {

    public typealias Response = PagedPlaylistsJSON

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, limit: Int = 50, offset: Int = 0) {
            guard (1...50) ~= limit else { fatalError("limit must be between 1 and 50") }
            var urlComponents = URLComponents(url: URL(string: "/v1/me/playlists", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "limit", value: "\(limit)"), URLQueryItem(name: "offset", value: "\(offset)")]
            urlRequest = URLRequest(url: urlComponents.url!)
        }
    }
}

extension SpotifyWebApi.Playlists.GetPlaylistTracks {
    public typealias Response = PagedTracksJSON

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, playlistId: String, offset: Int = 0) {
            var urlComponents = URLComponents(url: URL(string: "/v1/playlists/\(playlistId)/tracks", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "offset", value: "\(offset)")]
            urlRequest = URLRequest(url: urlComponents.url!)
        }
    }
}

public protocol SpotifyPlaylistsGateway {
    func getUserPlaylists(limit: Int, offset: Int) -> AnyPublisher<PagedPlaylistsJSON, Error>
    func getPlaylistTracks(playlistId: String, offset: Int) -> AnyPublisher<PagedTracksJSON, Error>
    func getNextPlaylistTracks(next:URL) -> AnyPublisher<PagedTracksJSON, Error>
}

public class SpotifyPlaylistsGatewayImplementation: BaseSpotifyGateway, SpotifyPlaylistsGateway {

    public func getUserPlaylists(limit: Int = 50, offset: Int = 0) -> AnyPublisher<PagedPlaylistsJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetUserPlaylists.Request(baseURL: baseURL, limit: limit, offset: offset)
        return requestManager.execute(request: request)
    }

    public func getPlaylistTracks(playlistId: String, offset: Int = 0) -> AnyPublisher<PagedTracksJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetPlaylistTracks.Request(baseURL: baseURL, playlistId: playlistId, offset: offset)
        return requestManager.execute(request: request)
    }

    public func getNextPlaylistTracks(next: URL) -> AnyPublisher<PagedTracksJSON, Error> {
        return requestManager.execute(urlRequest: URLRequest(url: next))
    }
}
