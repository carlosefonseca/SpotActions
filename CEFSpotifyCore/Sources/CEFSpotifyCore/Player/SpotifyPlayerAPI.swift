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

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/play", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "PUT"
        }
    }
}

extension SpotifyWebApi.Player.Pause {
    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/pause", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "PUT"
        }
    }
}

extension SpotifyWebApi.Player.Previous {
    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/previous", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
        }
    }
}

extension SpotifyWebApi.Player.Next {
    public struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/next", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
        }
    }
}

public protocol SpotifyPlayerGateway {
    func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error>
    func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, Error>

    func playPublisher() -> AnyPublisher<Data, Error>
    func pausePublisher() -> AnyPublisher<Data, Error>
    func nextPublisher() -> AnyPublisher<Data, Error>
    func previousPublisher() -> AnyPublisher<Data, Error>

    func play()
    func pause()
    func next()
    func previous()
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

    public func playPublisher() -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Play.Request(baseURL: baseURL)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func pausePublisher() -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Pause.Request(baseURL: baseURL)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func nextPublisher() -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Next.Request(baseURL: baseURL)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func previousPublisher() -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Previous.Request(baseURL: baseURL)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func play() {
        _ = playPublisher().print("SpotifyPlayerGateway.play()").sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    public func pause() {
        _ = pausePublisher().print("SpotifyPlayerGateway.pause()").sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    public func next() {
        _ = nextPublisher().print("SpotifyPlayerGateway.next()").sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    public func previous() {
        _ = previousPublisher().print("SpotifyPlayerGateway.previous()").sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}
