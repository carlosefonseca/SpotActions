//
//  SpotifyPlaylists.swift
//

import Foundation
import Combine

public extension SpotifyWebApi.Playlists {
    enum GetUserPlaylists {}
    enum GetPlaylistTracks {}
    enum GetPlayerRecentlyPlayed {}
    enum PutPlaylistItems {}

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

extension SpotifyWebApi.Playlists.GetPlayerRecentlyPlayed {
    public typealias Response = PagedTracksJSON

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/recently-played", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
        }
    }
}

extension SpotifyWebApi.Playlists.PutPlaylistItems {
    public typealias Response = Void

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, playlist: SpotifyURI, tracks: URIListJSON) throws {
            let urlComponents = URLComponents(url: URL(string: "/v1/playlists/\(playlist)/tracks", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            var request = URLRequest(url: urlComponents.url!)
            do {
                let data = try JSONEncoder().encode(tracks)
                request.httpBody = data
                request.httpMethod = "PUT"
            } catch {
                throw SpotifyRequestError.requestError(error: error)
            }
            urlRequest = request
        }
    }
}

public protocol SpotifyPlaylistsGateway {
    func getUserPlaylists(limit: Int, offset: Int) -> AnyPublisher<PagedPlaylistsJSON, Error>
    func getPlaylistTracks(playlistId: String, offset: Int) -> AnyPublisher<PagedTracksJSON, Error>
    func getNextPlaylistTracks(next: URL) -> AnyPublisher<PagedTracksJSON, Error>
    func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error>
    func save(tracks: [String], on playlistId: String) throws -> AnyPublisher<Never, Error>
}

public class SpotifyPlaylistsGatewayImplementation: BaseSpotifyGateway, SpotifyPlaylistsGateway {

    public func getUserPlaylists(limit: Int = 50, offset: Int = 0) -> AnyPublisher<PagedPlaylistsJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetUserPlaylists.Request(baseURL: baseURL, limit: limit, offset: offset)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Playlists.GetUserPlaylists.Response.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    public func getPlaylistTracks(playlistId: String, offset: Int = 0) -> AnyPublisher<PagedTracksJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetPlaylistTracks.Request(baseURL: baseURL, playlistId: playlistId, offset: offset)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Playlists.GetPlaylistTracks.Response.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    public func getNextPlaylistTracks(next: URL) -> AnyPublisher<PagedTracksJSON, Error> {
        return requestManager.execute(urlRequest: URLRequest(url: next))
            .decode(type: SpotifyWebApi.Playlists.GetPlaylistTracks.Response.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    public func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetPlayerRecentlyPlayed.Request(baseURL: baseURL)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Playlists.GetPlayerRecentlyPlayed.Response.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    public func save(tracks: [SpotifyURI], on playlistId: String) throws -> AnyPublisher<Never, Error> {
        let request = try SpotifyWebApi.Playlists.PutPlaylistItems.Request(baseURL: baseURL, playlist: playlistId, tracks: URIListJSON(uris: tracks))
        print("SpotifyPlaylists.save \(request.urlRequest)")
        print("SpotifyPlaylists.save \(String(data: request.urlRequest.httpBody!, encoding: .utf8))")
        return requestManager.execute(request: request).print("SpotifyPlaylists.save").ignoreOutput().eraseToAnyPublisher()
    }
}
