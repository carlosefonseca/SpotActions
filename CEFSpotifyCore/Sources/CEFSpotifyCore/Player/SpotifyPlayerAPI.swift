//
// SpotifyPlayerAPI.swift
//

import Foundation
import Combine

public extension SpotifyWebApi.Player {
    enum GetCurrentlyPlaying {}
    enum GetRecentlyPlayed {}
}

extension SpotifyWebApi.Player.GetCurrentlyPlaying {
    public typealias Response = CurrentlyPlayingJSON

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let url = URL(string: "/v1/me/player/currently-playing", relativeTo: baseURL)!
            urlRequest = URLRequest(url: url)
        }
    }
}

extension SpotifyWebApi.Player.GetRecentlyPlayed {
    public typealias Response = PagedTracksJSON

    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            var urlComponents = URLComponents(url: URL(string: "/v1/me/player/recently-played", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "limit", value: "50")]
            urlRequest = URLRequest(url: urlComponents.url!)
        }
    }
}

public protocol SpotifyPlayerGateway {
    func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error>
    func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON, Error>
}

public class SpotifyPlayerGatewayImplementation: BaseSpotifyGateway, SpotifyPlayerGateway {
    public func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error> {
        let request = SpotifyWebApi.Player.GetRecentlyPlayed.Request(baseURL: baseURL)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Player.GetRecentlyPlayed.Response.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    public func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON, Error> {
        let request = SpotifyWebApi.Player.GetCurrentlyPlaying.Request(baseURL: baseURL)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Player.GetCurrentlyPlaying.Response.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
