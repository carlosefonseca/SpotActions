//
//  SpotifyPlaylists.swift
//

import Foundation
import Combine

public extension SpotifyWebApi.Playlists {
    enum GetUserPlaylists {}
    enum GetPlaylistTracks {}
    enum PutPlaylistItems {}
    enum PostPlaylistItems {}
    enum GetPlaylist {}

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

extension SpotifyWebApi.Playlists.PutPlaylistItems {
    public typealias Response = Void

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, playlist: SpotifyURI, tracks: URIListJSON) throws {
            guard tracks.uris.count <= 100 else { throw SpotifyRequestError.otherError(message: "Can only set 100 items using this method!") }
            let urlComponents = URLComponents(url: URL(string: "/v1/playlists/\(playlist)/tracks", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            var request = URLRequest(url: urlComponents.url!)
            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
                let data = try jsonEncoder.encode(tracks)
                request.httpBody = data
                request.httpMethod = "PUT"
            } catch {
                throw SpotifyRequestError.requestError(error: error)
            }
            urlRequest = request
        }
    }
}

extension SpotifyWebApi.Playlists.PostPlaylistItems {
    public typealias Response = Void

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, playlist: SpotifyURI, tracks: URIListJSON) throws {
            guard tracks.uris.count <= 100 else { throw SpotifyRequestError.otherError(message: "Can only set 100 items using this method!") }
            let urlComponents = URLComponents(url: URL(string: "/v1/playlists/\(playlist)/tracks", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            var request = URLRequest(url: urlComponents.url!)
            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
                let data = try jsonEncoder.encode(tracks)
                request.httpBody = data
                request.httpMethod = "POST"
            } catch {
                throw SpotifyRequestError.requestError(error: error)
            }
            urlRequest = request
        }
    }
}

extension SpotifyWebApi.Playlists.GetPlaylist {
    public typealias Response = PlaylistJSON

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, playlistId: SpotifyID) {
            let url = URL(string: "/v1/playlists/\(playlistId)", relativeTo: baseURL)!
            urlRequest = URLRequest(url: url)
        }
    }
}

public protocol SpotifyPlaylistsGateway {
    func getUserPlaylists(limit: Int, offset: Int) -> AnyPublisher<PagedPlaylistsJSON, Error>
    func getNextUserPlaylists(next: URL) -> AnyPublisher<PagedPlaylistsJSON, Error>
    func getPlaylistTracks(playlistId: String, offset: Int) -> AnyPublisher<PagedTracksJSON, Error>
    func getNextPlaylistTracks(next: URL) -> AnyPublisher<PagedTracksJSON, Error>
    func replace(tracks: [String], on playlistId: String) throws -> AnyPublisher<Never, Error>
    func add(tracks: [SpotifyURI], to playlistId: String, at index: Int?) throws -> AnyPublisher<Never, Error>
    func getPlaylist(playlistId: SpotifyID) -> AnyPublisher<PlaylistJSON, Error>
}

public class SpotifyPlaylistsGatewayImplementation: BaseSpotifyGateway, SpotifyPlaylistsGateway {
    public func getUserPlaylists(limit: Int = 50, offset: Int = 0) -> AnyPublisher<PagedPlaylistsJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetUserPlaylists.Request(baseURL: baseURL, limit: limit, offset: offset)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Playlists.GetUserPlaylists.Response.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    public func getPlaylistTracks(playlistId: String, offset: Int = 0) -> AnyPublisher<PagedTracksJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetPlaylistTracks.Request(baseURL: baseURL, playlistId: playlistId, offset: offset)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Playlists.GetPlaylistTracks.Response.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    private func getNext<T>(next: URL) -> AnyPublisher<PagingJSON<T>, Error> where T : Decodable, T : Encodable, T : Equatable {
        return requestManager.execute(urlRequest: URLRequest(url: next))
            .decode(type: PagingJSON<T>.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    public func getNextUserPlaylists(next: URL) -> AnyPublisher<PagedPlaylistsJSON, Error> {
        return getNext(next: next)
    }

    public func getNextPlaylistTracks(next: URL) -> AnyPublisher<PagedTracksJSON, Error> {
        return getNext(next: next)
    }

    public func replace(tracks: [SpotifyURI], on playlistId: String) throws -> AnyPublisher<Never, Error> {
        let request = try SpotifyWebApi.Playlists.PutPlaylistItems.Request(baseURL: baseURL, playlist: playlistId, tracks: URIListJSON(uris: tracks))
        return requestManager.execute(request: request).print("SpotifyPlaylists.save").ignoreOutput().eraseToAnyPublisher()
    }

    public func add(tracks: [SpotifyURI], to playlistId: String, at index: Int?) throws -> AnyPublisher<Never, Error> {
        let request = try SpotifyWebApi.Playlists.PostPlaylistItems.Request(baseURL: baseURL, playlist: playlistId, tracks: URIListJSON(uris: tracks, position: index))
        return requestManager.execute(request: request)
            .print("SpotifyPlaylists.add")
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    public func getPlaylist(playlistId: SpotifyID) -> AnyPublisher<PlaylistJSON, Error> {
        let request = SpotifyWebApi.Playlists.GetPlaylist.Request(baseURL: baseURL, playlistId: playlistId)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Playlists.GetPlaylist.Response.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}
