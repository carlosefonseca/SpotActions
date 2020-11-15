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
    enum Devices {}
    enum TransferPlayback {}
}

public extension SpotifyWebApi.Player.GetCurrentlyPlaying {
    typealias Response = CurrentlyPlayingJSON?

    struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let url = URL(string: "/v1/me/player/currently-playing", relativeTo: baseURL)!
            urlRequest = URLRequest(url: url)
        }
    }
}

public extension SpotifyWebApi.Player.GetRecentlyPlayed {
    typealias Response = PagedTracksJSON

    struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            var urlComponents = URLComponents(url: URL(string: "/v1/me/player/recently-played", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "limit", value: "50")]
            urlRequest = URLRequest(url: urlComponents.url!)
        }
    }
}

public extension SpotifyWebApi.Player.Play {
    struct PlayBody: Encodable {
        var contextUri: SpotifyURI
    }

    struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL, contextUri: SpotifyURI? = nil, deviceId: String? = nil) {
            var urlComponents = URLComponents(url: URL(string: "/v1/me/player/play", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!

            if let deviceId = deviceId {
                urlComponents.queryItems = [URLQueryItem(name: "device_id", value: deviceId)]
            }

            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "PUT"

            if let context = contextUri {
                let body = PlayBody(contextUri: context)
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                urlRequest.httpBody = try? encoder.encode(body)
            }
        }
    }
}

public extension SpotifyWebApi.Player.Pause {
    struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/pause", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "PUT"
        }
    }
}

public extension SpotifyWebApi.Player.Previous {
    struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/previous", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
        }
    }
}

public extension SpotifyWebApi.Player.Next {
    struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/next", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
        }
    }
}

public extension SpotifyWebApi.Player.Devices {

    struct DevicesResponse: Decodable {
        var devices: [DeviceJSON]
    }

    typealias Response = DevicesResponse

    struct Request: URLRequestable {
        public var urlRequest: URLRequest

        init(baseURL: URL) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player/devices", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "GET"
        }
    }
}

public extension SpotifyWebApi.Player.TransferPlayback {
    struct Request: URLRequestable {

        struct Body: Encodable {
            var deviceIds: [String]
            var play: Bool = true

            init(deviceId: String, play: Bool = true) {
                self.deviceIds = [deviceId]
                self.play = play
            }
        }

        public var urlRequest: URLRequest

        var encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return encoder
        }()

        init(baseURL: URL, deviceId: SpotifyID) {
            let urlComponents = URLComponents(url: URL(string: "/v1/me/player", relativeTo: baseURL)!, resolvingAgainstBaseURL: true)!
            urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "PUT"
            urlRequest.httpBody = try! encoder.encode(Body(deviceId: deviceId))
        }
    }
}

public protocol SpotifyPlayerGateway {
    func getRecentlyPlayed() -> AnyPublisher<PagedTracksJSON, Error>
    func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, Error>

    func play(contextUri: SpotifyURI?, deviceId: String?) -> AnyPublisher<Data, Error>
    func pause() -> AnyPublisher<Data, Error>
    func next() -> AnyPublisher<Data, Error>
    func previous() -> AnyPublisher<Data, Error>

    func devices() -> AnyPublisher<[DeviceJSON], Error>

    func transferPlayback(to device: SpotifyID) -> AnyPublisher<Data, Error>
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
            .filter { !$0.isEmpty }
            .decode(type: SpotifyWebApi.Player.GetCurrentlyPlaying.Response.self, decoder: decoder)
            .replaceEmpty(with: nil)
            .handleEvents(receiveCompletion: { completion in
                if case Subscribers.Completion.failure(let error) = completion {
                    print("FAILS WHEN NOTHING IS PLAYING")
                    print((error as? DecodingError)?.debugDescription ?? error)
                }
            })
            .print("SpotifyPlayerGateway.getCurrentlyPlaying() 2")
            .eraseToAnyPublisher()
    }

    public func play(contextUri: SpotifyURI? = nil, deviceId: String? = nil) -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Play.Request(baseURL: baseURL, contextUri: contextUri, deviceId: deviceId)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func pause() -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Pause.Request(baseURL: baseURL)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func next() -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Next.Request(baseURL: baseURL)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func previous() -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.Previous.Request(baseURL: baseURL)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }

    public func devices() -> AnyPublisher<[DeviceJSON], Error> {
        let request = SpotifyWebApi.Player.Devices.Request(baseURL: baseURL)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.Player.Devices.Response.self, decoder: decoder)
            .map { $0.devices }
            .eraseToAnyPublisher()
    }

    public func transferPlayback(to deviceId: SpotifyID) -> AnyPublisher<Data, Error> {
        let request = SpotifyWebApi.Player.TransferPlayback.Request(baseURL: baseURL, deviceId: deviceId)
        return requestManager.execute(request: request).eraseToAnyPublisher()
    }
}
