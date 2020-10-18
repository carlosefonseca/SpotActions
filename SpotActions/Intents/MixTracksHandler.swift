//
// MixTracksHandler.swift
//

import Intents
import CEFSpotifyCore
import Combine

class MixTracksHandler: NSObject, MixTracksIntentHandling {

    let auth: SpotifyAuthManager
    let playlistsManager: PlaylistsManager
    let trackMixerService: TrackMixerService
    var bag = Set<AnyCancellable>()

    public init(auth: SpotifyAuthManager, playlistsManager: PlaylistsManager, trackMixerService: TrackMixerService) {
        self.auth = auth
        self.playlistsManager = playlistsManager
        self.trackMixerService = trackMixerService
    }

    func handle(intent: MixTracksIntent, completion: @escaping (MixTracksIntentResponse) -> Void) {

        let mode: INMixType = intent.mode

        guard let playlists = intent.playlists else {
            completion(.failure(error: "Playlists is nil"))
            return
        }

        let p1: AnyPublisher<[Track], PlaylistsManagerError> =
            playlistsManager.getMultiplePlaylistTracks(playlistIds: playlists.map { $0.id })
                .map { set in set.map { $0 as Track } }
                .eraseToAnyPublisher()

        let trackSetsPublisher: AnyPublisher<[Track], PlaylistsManagerError> =
            [intent.tracks1, intent.tracks2, intent.tracks3, intent.tracks4, intent.tracks5,
             intent.tracks6, intent.tracks7, intent.tracks8, intent.tracks9, intent.tracks10]
            .compactMap { set in set?.map { track in track as Track } }
            .publisher
            .setFailureType(to: PlaylistsManagerError.self)
            .eraseToAnyPublisher()

        let x: AnyPublisher<[Track], PlaylistsManagerError> =
            p1.append(trackSetsPublisher)
                .eraseToAnyPublisher()

        let trackSetsArrayPublisher: AnyPublisher<[[Track]], PlaylistsManagerError> =
            x
                .filter { !$0.isEmpty }
                .collect()
                .eraseToAnyPublisher()

        let mixedTracksPublisher: AnyPublisher<[Track], PlaylistsManagerError> =
            trackSetsArrayPublisher
                .flatMap { self.trackMixerService.mix(trackSets: $0, mixMode: mode.asMixMode) }
                .eraseToAnyPublisher()

        mixedTracksPublisher.sink(
            receiveCompletion: { compl in
                if case .failure(let error) = compl {
                    completion(.failure(error: error.localizedDescription))
                }
            },
            receiveValue: {
                completion(.success(result: $0.map { $0 as? INTrack ?? INTrack(from: $0) }))
            }
        )
        .store(in: &bag)
    }

    func providePlaylistsOptionsCollection(for intent: MixTracksIntent, with completion: @escaping (INObjectCollection<INPlaylist>?, Error?) -> Void) {
        guard case .loggedIn = auth.state else {
            completion(nil, "Not logged in!")
            return
        }

        playlistsManager.getFirstPageUserPlaylists()
            .sink(
                receiveCompletion: { receiveCompletion in
                    if case .failure(let error) = receiveCompletion {
                        completion(nil, error)
                    }
                },
                receiveValue: { value in
                    completion(INObjectCollection(items: value.map { INPlaylist(from: $0) }), nil)
                }
            ).store(in: &bag)
    }
}

extension INMixType {
    var asMixMode: MixMode {
        switch self {
        case .unknown:
            fatalError()
        case .concat:
            return .concat
        case .alternate:
            return .alternate
        case .mix:
            return .mix
        }
    }
}
