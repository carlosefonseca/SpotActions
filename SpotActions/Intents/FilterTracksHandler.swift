//
// FilterTracksHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

class FilterTracksHandler: NSObject, FilterTracksIntentHandling {
    let playlistsManager: PlaylistsManager
    var bag = Set<AnyCancellable>()

    var filterService: TrackFilterService

    init(playlistsManager: PlaylistsManager, trackFilterService: TrackFilterService) {
        self.playlistsManager = playlistsManager
        self.filterService = trackFilterService
    }

    func handle(intent: FilterTracksIntent, completion: @escaping (FilterTracksIntentResponse) -> Void) {
        guard
            let tracks = intent.tracks,
            !tracks.isEmpty
        else {
            completion(.failure(error: "No tracks specified!"))
            return
        }

        var select: Bool!

        switch intent.mode {
        case .unknown:
            completion(.failure(error: "No select/reject specified!"))
            return
        case .select:
            select = true
        case .reject:
            select = false
        }

        var result: Result<[INTrack], ErrorMessage>?

        switch intent.filter {
        case .unknown:
            completion(.failure(error: "No filter specified!"))
            return

        case .titleAndArtist:
            result = filterService.filterByTitleArtist(modeIsSelect: select,
                                                       tracks: tracks,
                                                       titles: intent.andTitles,
                                                       artists: intent.andArtists,
                                                       and: true,
                                                       isRegex: intent.andIsRegex?.boolValue ?? false)
        case .titleOrArtist:
            result = filterService.filterByTitleArtist(modeIsSelect: select,
                                                       tracks: tracks,
                                                       titles: intent.orTitles,
                                                       artists: intent.orArtists,
                                                       and: false,
                                                       isRegex: intent.orIsRegex?.boolValue ?? false)

        case .existInPlaylist:
            guard let otherPlaylist = intent.otherPlaylist else {
                completion(.failure(error: "Other playlist not selected!"))
                return
            }
            guard let otherPlaylistId = otherPlaylist.identifier else {
                completion(.failure(error: "Other playlist doesn't have an id. (?)"))
                return
            }

            filterService.existsInPlaylist(modeIsSelect: select, tracks: tracks, otherPlaylistId: otherPlaylistId)
                .sink { complete in
                    if case .failure(let error) = complete {
                        completion(.failure(error: error))
                    }
                } receiveValue: { result in
                    completion(.success(result: result))
                }.store(in: &bag)

            return

        case .existInTracks:
            let otherTracks = intent.otherTracks ?? []
            result = .success(
                filterService.filterTracksWithOtherTracks(modeIsSelect: select,
                                                          tracks: tracks,
                                                          otherTracks: otherTracks)
            )
        case .dedup:
            result = .success(
                filterService.duplicatedTracks(modeIsSelect: select, tracks: tracks)
            )
        case .limit:

            let mode = intent.limitMode.asLimitMode
            var amount = Int(truncating: intent.amount ?? 0)
            let unit: LimitUnit

            switch intent.unit {
            case .tracks:
                unit = .tracks
            case .minutes:
                unit = .minutes
            case .hours:
                unit = .minutes
                amount = amount * 60
            case .unknown:
                completion(.failure(error: "Missing Limit Unit!"))
                return
            }

            let extractedExpr: [INTrack] = filterService.limitTracks(modeIsSelect: select,
                                                                     tracks: tracks,
                                                                     mode: mode,
                                                                     amount: amount,
                                                                     unit: unit)

            result = .success(
                extractedExpr
            )
        }

        switch result {
        case .success(let output):
            completion(.success(result: output))
        case .failure(let error):
            completion(.failure(error: error))
        case .none:
            completion(.failure(error: "Error! Maybe not implemented."))
        }
    }

    func provideOtherPlaylistOptionsCollection(for intent: FilterTracksIntent, with completion: @escaping (INObjectCollection<INPlaylist>?, Error?) -> Void) {
        playlistsManager.getFirstPageUserPlaylists()
            .sink(receiveCompletion: { receiveCompletion in
                if case .failure(let error) = receiveCompletion {
                    completion(nil, error)
                }
            },
                  receiveValue: { value in
                completion(INObjectCollection(items: value.map { INPlaylist(from: $0) }), nil)
            }).store(in: &bag)
    }
}

extension INLimitMode {
    var asLimitMode: LimitMode {
        switch self {
        case .first:
            return LimitMode.first
        case .last:
            return LimitMode.last
        case .any:
            return LimitMode.any
        case .unknown:
            fatalError("No Limit Mode selected")
        }
    }
}
