//
// PlayerManager.swift
//

import Foundation
import Combine

public protocol PlayerManager {
    func getRecentlyPlayed() -> AnyPublisher<[TrackJSON], PlayerError>
    func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, PlayerError>

    func play(contextUri: SpotifyURI?, deviceId: String?) -> AnyPublisher<Data, Error>
    func pause() -> AnyPublisher<Data, Error>
    func next() -> AnyPublisher<Data, Error>
    func previous() -> AnyPublisher<Data, Error>

    func devices() -> AnyPublisher<[DeviceJSON], Error>
    func transferPlayback(to device: SpotifyID) -> AnyPublisher<Data, Error>
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
        gateway.getRecentlyPlayed()
            .mapError { PlayerError.requestError(error: $0) }
            .map { $0.items!.map { $0.track! } }
            .eraseToAnyPublisher()
    }

    public func getCurrentlyPlaying() -> AnyPublisher<CurrentlyPlayingJSON?, PlayerError> {
        gateway.getCurrentlyPlaying()
            .mapError { PlayerError.requestError(error: $0) }
            .eraseToAnyPublisher()
    }

    public func play(contextUri: SpotifyURI? = nil, deviceId: String?) -> AnyPublisher<Data, Error> {
        gateway.play(contextUri: contextUri, deviceId: deviceId)
    }

    public func pause() -> AnyPublisher<Data, Error> { gateway.pause() }
    public func next() -> AnyPublisher<Data, Error> { gateway.next() }
    public func previous() -> AnyPublisher<Data, Error> { gateway.previous() }

    public func devices() -> AnyPublisher<[DeviceJSON], Error> {
        gateway.devices()
    }

    public func transferPlayback(to device: SpotifyID) -> AnyPublisher<Data, Error> {
        gateway.transferPlayback(to: device)
    }
}
