//
// FilterTracksHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

typealias ErrorMessage = String
extension ErrorMessage: Error {}

class FilterTracksHandler: NSObject, FilterTracksIntentHandling {
    let playlistsManager: PlaylistsManager
    var bag = Set<AnyCancellable>()

    init(playlistsManager: PlaylistsManager) {
        self.playlistsManager = playlistsManager
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
            result = filterByTitleArtist(modeIsSelect: select,
                                         tracks: tracks,
                                         titles: intent.andTitles,
                                         artists: intent.andArtists,
                                         and: true,
                                         isRegex: intent.andIsRegex?.boolValue ?? false)
        case .titleOrArtist:
            result = filterByTitleArtist(modeIsSelect: select,
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
            filterByExistsInPlaylist(modeIsSelect: select, tracks: tracks, playlist: otherPlaylistId)
                .sink { complete in
                    if case .failure(let error) = complete {
                        completion(.failure(error: error))
                    }
                } receiveValue: { result in
                    completion(.success(result: result))
                }.store(in: &bag)
            return

        case .dedup:
            break
        case .existInTracks:
            break
        case .first:
            break
        case .last:
            break
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

    func filterByTitleArtist(modeIsSelect: Bool, tracks: [INTrack], titles: [String]?, artists: [String]?, and: Bool, isRegex: Bool) -> Result<[INTrack], ErrorMessage> {
        var titleRegex: NSRegularExpression?
        if let titles = titles {
            do {
                titleRegex = try createRegexFrom(strings: titles, escaped: !isRegex)
                print("Title Regex: \(titleRegex)")
            } catch {
                return Result.failure("Failed to parse titles regex!")
            }
        }

        var artistRegex: NSRegularExpression?
        if let artists = artists {
            do {
                artistRegex = try createRegexFrom(strings: artists, escaped: !isRegex)
                print("Artist Regex: \(artistRegex)")
            } catch {
                return .failure("Failed to parse artists regex!")
            }
        }

        let filtered: [INTrack]
        if modeIsSelect {
            if and {
                filtered = tracks.filter { $0.matches(title: titleRegex, andArtist: artistRegex) }
            } else {
                filtered = tracks.filter { $0.matches(title: titleRegex, orArtist: artistRegex) }
            }
        } else {
            if and {
                filtered = tracks.filter { !$0.matches(title: titleRegex, andArtist: artistRegex) }
            } else {
                filtered = tracks.filter { !$0.matches(title: titleRegex, orArtist: artistRegex) }
            }
        }
        return .success(filtered)
    }

    func filterByExistsInPlaylist<T: Track>(modeIsSelect: Bool, tracks: [T], playlist: SpotifyID) -> AnyPublisher<[T], ErrorMessage> {

        playlistsManager.getAllPlaylistTracks(playlistId: playlist)
            .mapError { error in error.errorDescription ?? "Error" }
            .map { otherPlaylistTracks in

                let possibleIds = self.allIdsForTracks(tracks: otherPlaylistTracks)

                let otherExternalIds = otherPlaylistTracks.flatMap { track in
                    track.externalIds?.compactMap { type, value in "\(type):\(value)" } ?? []
                }

                return tracks.filter { (track) -> Bool in

                    let containsURI = possibleIds.contains(track.id)

                    let trackExistsInOtherPlaylist = containsURI || self.track(track, matchesExternalIds: otherExternalIds)

                    if modeIsSelect {
                        return trackExistsInOtherPlaylist
                    } else {
                        return !trackExistsInOtherPlaylist
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    func allIdsForTracks(tracks: [TrackJSON]) -> Set<String> {
        let otherIds = Set(tracks.compactMap { (track) -> String? in track.id })
        let linkedIds = Set(tracks.compactMap { track in track.linkedFrom?.id })
        return otherIds.union(linkedIds)
    }

    func track<T: Track>(_ track: T, matchesExternalIds otherExternalIds: [String]) -> Bool {
        return (track.externalIdsStr ?? [])
            .first(where: { otherExternalIds.contains($0) }) != nil
    }

    func provideOtherPlaylistOptionsCollection(for intent: FilterTracksIntent, with completion: @escaping (INObjectCollection<INPlaylist>?, Error?) -> Void) {
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

    private func createRegexFrom(strings: [String], escaped: Bool) throws -> NSRegularExpression {
        let join = strings.map { escaped ? NSRegularExpression.escapedPattern(for: $0) : $0 }.joined(separator: ")|(")
        return try NSRegularExpression(pattern: "(\(join))")
    }
}

extension String {
    func contains(regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

private extension INTrack {
    func matches(title titleRegex: NSRegularExpression?, andArtist artistRegex: NSRegularExpression?) -> Bool {
        var matchTitle: Bool = true
        if let titleRegex = titleRegex {
            matchTitle = title?.contains(regex: titleRegex) ?? true
        }

        var matchArtist = true
        if let artistRegex = artistRegex {
            matchArtist = (artists?.first(where: { artist in artist.displayString.contains(regex: artistRegex) }) != nil)
        }

        print("\(displayString) title: \(matchTitle) && artist: \(matchArtist) = \(matchTitle && matchArtist) ")

        return matchTitle && matchArtist
    }

    func matches(title titleRegex: NSRegularExpression?, orArtist artistRegex: NSRegularExpression?) -> Bool {
        if let titleRegex = titleRegex,
            title?.contains(regex: titleRegex) == true {
            print("\(displayString) title: true")
            return true
        }

        if let artistRegex = artistRegex,
            artists?.first(where: { artist in artist.displayString.contains(regex: artistRegex) }) != nil {
            print("\(displayString) title: false || artist: true = true ")
            return true
        }

        print("\(displayString) title: false || artist: false = false ")
        return false
    }
}
