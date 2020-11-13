//
// PlayerManager.swift
//

import Foundation
import Combine

public protocol PlayerManager {
    func getRecentlyPlayed() -> AnyPublisher<[TrackJSON], PlayerError>
    func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, PlayerError>

    func play() -> AnyPublisher<Data, Error>
    func pause() -> AnyPublisher<Data, Error>
    func next() -> AnyPublisher<Data, Error>
    func previous() -> AnyPublisher<Data, Error>
}

public enum PlayerError: Error {
    case missingData(message: String)
    case requestError(error: Error)
}

public class PlayerManagerImplementation: PlayerManager {
    let gateway: SpotifyPlayerGateway

    public init(gateway: SpotifyPlayerGateway) {
        self.gateway = gateway
    }

    public func getRecentlyPlayed() -> AnyPublisher<[TrackJSON], PlayerError> {
        self.gateway.getRecentlyPlayed()
            .mapError { PlayerError.requestError(error: $0) }
            .map { $0.items!.map { $0.track! } }
            .eraseToAnyPublisher()
    }

    public func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, PlayerError> {
        self.gateway.getCurrentlyPlaying()
            .mapError { PlayerError.requestError(error: $0) }
            .eraseToAnyPublisher()
    }

    public func play() -> AnyPublisher<Data, Error> { self.gateway.playPublisher() }
    public func pause() -> AnyPublisher<Data, Error> { self.gateway.pausePublisher() }
    public func next() -> AnyPublisher<Data, Error> { self.gateway.nextPublisher() }
    public func previous() -> AnyPublisher<Data, Error> { self.gateway.previousPublisher() }
}
