//
// GetPlayingTrackHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

enum GetPlayingTrackHandlerError: Error {
    case message(_ message: String)
}

class GetPlayingTrackHandler: NSObject, GetPlayingTrackIntentHandling {
    let auth: SpotifyAuthManager
    let playerManager: PlayerManager

    var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, playerManager: PlayerManager) {
        self.auth = auth
        self.playerManager = playerManager
    }

    private func processForTrack() -> AnyPublisher<TrackJSON?, PlayerError> {
        playerManager.getCurrentlyPlaying()
            .map { $0.item }
            .eraseToAnyPublisher()
    }

    func handle(intent: GetPlayingTrackIntent, completion: @escaping (GetPlayingTrackIntentResponse) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(.failure(error: "Not logged in!"))
            return
        }

        processForTrack()
            .sink(
                receiveCompletion: { compl in
                    if case .failure(let error) = compl {
                        completion(.failure(error: error.localizedDescription))
                    }
                },
                receiveValue: {
                    guard let trackJson = $0 else {
                        completion(.init(code: .nothingPlaying, userActivity: nil))
                        return
                    }
                    let result = INTrack(from: trackJson)
                    completion(.success(result: result))
                }
            )
            .store(in: &bag)
    }
}
