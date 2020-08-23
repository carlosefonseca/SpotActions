//
//  SpotifyPlaylists.swift
//

import Foundation

public extension SpotifyWebApi.Playlists {
    enum ListCurrentUserPlaylists {}
    enum GetPlaylist {}
    enum CreatePlaylist {}

    enum GetItems {}
    enum AddItems {}
    enum RemoveItems {}
    enum ReorderItems {}
    enum ReplaceItems {}
}

extension SpotifyWebApi.Playlists.ListCurrentUserPlaylists {

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

public protocol SpotifyPlaylistsGateway {
    func listUserPlaylists(limit: Int, offset: Int, callback: @escaping (Result<SpotifyWebApi.Playlists.ListCurrentUserPlaylists.Response, SpotifyRequestError>) -> Void)
}

public class SpotifyPlaylistsGatewayImplementation: BaseSpotifyGateway, SpotifyPlaylistsGateway {
    public func listUserPlaylists(limit: Int = 50, offset: Int = 0, callback: @escaping (Result<SpotifyWebApi.Playlists.ListCurrentUserPlaylists.Response, SpotifyRequestError>) -> Void) {
        let request = SpotifyWebApi.Playlists.ListCurrentUserPlaylists.Request(baseURL: baseURL, limit: limit, offset: offset)
        requestManager.execute(request: request) { (result: Result<SpotifyWebApi.Playlists.ListCurrentUserPlaylists.Response, SpotifyRequestError>) in
            callback(result)
        }
    }
}
