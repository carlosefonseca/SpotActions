//
// GetDetailsOfTrackHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

class GetDetailsOfTrackHandler: NSObject, GetDetailsOfTrackIntentHandling {

    var bag = Set<AnyCancellable>()

    func handle(intent: GetDetailsOfTrackIntent, completion: @escaping (GetDetailsOfTrackIntentResponse) -> Void) {

        guard let track = intent.track else {
            completion(.failure(error: "No track specified!"))
            return
        }

        switch intent.detail {

        case .artists:
            guard let artist = track.artists?.first else {
                completion(.failure(error: "Track has no artist!"))
                return
            }
            completion(.artist(track: track))
            return

        case .albumArtwork:

            guard let url = track.albumArtUrl else {
                completion(.failure(error: "Track does not have an album art!"))
                return
            }

            URLSession.shared.dataTaskPublisher(for: url)
                .sink { complete in
                    if case .failure(let error) = complete {
                        completion(.failure(error: "Error downloading album art. \(error.localizedDescription)"))
                        return
                    }
                } receiveValue: { (data: Data, response: URLResponse) in
//                    completion(.albumArtwork(albumArtwork: INFile(data: data, filename: response.suggestedFilename ?? "\(track.title!).jpg", typeIdentifier: .some(response.mimeType!))))
                    completion(.albumArtwork(track: track))
                }.store(in: &bag)
            return
        case .album:
            completion(.albumName(track: track))
            return
        case .duration:
            completion(.duration(track: track))
            return
        case .title:
            completion(.success(track: track))
            return
        case .unknown:
            completion(.failure(error: "No detail selected!"))
            return
        }
    }
}
