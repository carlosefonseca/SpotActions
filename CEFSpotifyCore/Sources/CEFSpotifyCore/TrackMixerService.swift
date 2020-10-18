//
// TrackMixerService.swift
//

import Foundation
import Combine

public enum MixMode {
    case concat, alternate, mix
}

public protocol TrackMixerService {
    func mix(trackSets: [[Track]], mixMode: MixMode) -> AnyPublisher<[Track], PlaylistsManagerError>
}

public class TrackMixerServiceImplementation: TrackMixerService {

    let playlistsManager: PlaylistsManager
    var bag = Set<AnyCancellable>()

    public init(playlistsManager: PlaylistsManager) {
        self.playlistsManager = playlistsManager
    }

    public func mix(trackSets: [[Track]], mixMode: MixMode) -> AnyPublisher<[Track], PlaylistsManagerError> {
        return Deferred {
            return Future { deferred in
                var tracks = [Track]()

                var slices: [ArraySlice<Track>]

                if mixMode == .concat {
                    tracks = trackSets.flatMap { $0 }
                } else {
                    if mixMode == .mix {
                        slices = trackSets.map { ArraySlice($0.shuffled()) }
                    } else {
                        slices = trackSets.map { ArraySlice($0) }
                    }

                    while !slices.isEmpty {
                        slices = slices.filter { !$0.isEmpty }
                            .map { trackSet -> ArraySlice<Track> in
                                tracks.append(trackSet.first!)
                                return trackSet.dropFirst()
                            }
                    }
                }

                deferred(.success(tracks))
            }
        }
        .eraseToAnyPublisher()
    }
}
