//
// SpotifyPlayerAPI.swift
//

import Foundation
import Combine

public extension SpotifyWebApi.Player {
    enum GetCurrentlyPlaying {}
    enum GetRecentlyPlayed {}
    enum Previous {}
    enum Next {}
    enum Play {}
    enum Pause {}
}

extension SpotifyWebApi.Player.GetCurrentlyPlaying {
    public typealias Response = CurrentlyPlayingJSON?

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

extension SpotifyWebApi.Player.Play {
    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, deviceId: String? = nil) {
            var urlComponents = URLComponents(url: URL(string: "/v1/me/player/play", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            if let deviceId = deviceId {
                urlComponents.queryItems = [URLQueryItem(name: "device_id", value: deviceId)]
            }
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "PUT"
        }
    }
}
extension SpotifyWebApi.Player.Pause {
    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            var urlComponents = URLComponents(url: URL(string: "/v1/me/player/pause", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "PUT"
        }
    }
}

extension SpotifyWebApi.Player.Previous {
    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, deviceId: String? = nil) {
            var urlComponents = URLComponents(url: URL(string: "/v1/me/player/play", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            if let deviceId = deviceId {
                urlComponents.queryItems = [URLQueryItem(name: "device_id", value: deviceId)]
            }
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
        }
    }
}

public protocol SpotifyPlayerGateway {
    func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error>
    func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, Error>
}

public class SpotifyPlayerGatewayImplementation: BaseSpotifyGateway, SpotifyPlayerGateway {
    public func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error> {
        let request = SpotifyWebApi.Player.GetRecentlyPlayed.Request(baseURL: baseURL)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Player.GetRecentlyPlayed.Response.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    public func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, Error> {
        let request = SpotifyWebApi.Player.GetCurrentlyPlaying.Request(baseURL: baseURL)
        return requestManager.execute(request: request)
            .print("SpotifyPlayerGateway.getCurrentlyPlaying() 1")
            .decode(type: SpotifyWebApi.Player.GetCurrentlyPlaying.Response.self, decoder: decoder)
            .handleEvents(receiveCompletion: { completion in
                if case Subscribers.Completion.failure(let error) = completion {
                    print("FAILS WHEN NOTHING IS PLAYING")
                    print((error as? DecodingError)?.debugDescription ?? error)
                }
            })
            .print("SpotifyPlayerGateway.getCurrentlyPlaying() 2")
            .eraseToAnyPublisher()
    }
}
