//
// TrackFilterService.swift
//

import Foundation
import Combine

public enum LimitMode {
    case first, last, any
}

public enum LimitUnit {
    case tracks, minutes
}

public protocol TrackFilterService {
    func filterByTitleArtist<T: Track>(modeIsSelect: Bool, tracks: [T], titles: [String]?, artists: [String]?, and: Bool, isRegex: Bool) -> Result<[T], ErrorMessage>
    func existsInPlaylist<T: Track>(modeIsSelect: Bool, tracks: [T], otherPlaylistId: String) -> AnyPublisher<[T], ErrorMessage>
    func filterTracksWithOtherTracks<T1: Track, T2: Track>(modeIsSelect: Bool, tracks: [T1], otherTracks: [T2]) -> [T1]
    func duplicatedTracks<T: Track>(modeIsSelect: Bool, tracks: [T]) -> [T]
    func limitTracks<T: Track>(modeIsSelect: Bool, tracks: [T], mode: LimitMode, amount: Int, unit: LimitUnit) -> [T]
}

public class TrackFilterServiceImplementation: TrackFilterService {
    var playlistsManager: PlaylistsManager

    public init(playlistsManager: PlaylistsManager) {
        self.playlistsManager = playlistsManager
    }

    public func filterByTitleArtist<T: Track>(modeIsSelect: Bool, tracks: [T], titles: [String]?, artists: [String]?, and: Bool, isRegex: Bool) -> Result<[T], ErrorMessage> {
        var titleRegex: NSRegularExpression?
        if let titles = titles {
            do {
                titleRegex = try createRegexFrom(strings: titles, escaped: !isRegex)
            } catch {
                return Result.failure("Failed to parse titles regex!")
            }
        }

        var artistRegex: NSRegularExpression?
        if let artists = artists {
            do {
                artistRegex = try createRegexFrom(strings: artists, escaped: !isRegex)
            } catch {
                return .failure("Failed to parse artists regex!")
            }
        }

        let filtered: [T]
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

    private func createRegexFrom(strings: [String], escaped: Bool) throws -> NSRegularExpression {
        let join = strings.map { escaped ? NSRegularExpression.escapedPattern(for: $0) : $0 }.joined(separator: ")|(")
        return try NSRegularExpression(pattern: "(\(join))")
    }

    // TODO: ADD TESTS
    public func existsInPlaylist<T: Track>(modeIsSelect: Bool, tracks: [T], otherPlaylistId: String) -> AnyPublisher<[T], ErrorMessage> {
        playlistsManager.getAllPlaylistTracks(playlistId: otherPlaylistId)
            .mapError { error in error.errorDescription ?? "Error" }
            .map { otherPlaylistTracks in
                self.filterTracksWithOtherTracks(modeIsSelect: modeIsSelect, tracks: tracks, otherTracks: otherPlaylistTracks)
            }
            .eraseToAnyPublisher()
    }

    public func filterTracksWithOtherTracks<T1: Track, T2: Track>(modeIsSelect: Bool, tracks: [T1], otherTracks: [T2]) -> [T1] {
        let possibleIds = otherTracks.trackIds()
        let otherExternalIds = otherTracks.flatMap { track in track.externalIdsStr ?? [] }

        return tracks.filter { (track) -> Bool in

            if possibleIds.contains(track.id) {
                return modeIsSelect
            }

            if let linkedTrack = track.linkedTrackId, possibleIds.contains(linkedTrack) {
                return modeIsSelect
            }

            if track.matches(externalIds: otherExternalIds) {
                return modeIsSelect
            }

            return !modeIsSelect
        }
    }

    public func duplicatedTracks<T>(modeIsSelect: Bool, tracks: [T]) -> [T] where T: Track {

        var possibleIds = Set<String>()
        var otherExternalIds = Set<String>()
        var uniqueTracks = [T]()
        var duplicatedTracks = [T]()

        tracks.forEach { track in

            if possibleIds.contains(track.id) {
                duplicatedTracks.append(track)
                return
            }

            if let linkedTrack = track.linkedTrackId, possibleIds.contains(linkedTrack) {
                duplicatedTracks.append(track)
                return
            }

            if let eIds = track.externalIdsStr, !otherExternalIds.isDisjoint(with: eIds) {
                duplicatedTracks.append(track)
                return
            }

            possibleIds.insert(track.id)
            if let linkedTrack = track.linkedTrackId {
                possibleIds.insert(linkedTrack)
            }

            if let eIds = track.externalIdsStr {
                otherExternalIds = otherExternalIds.union(eIds)
            }

            uniqueTracks.append(track)
        }

        if modeIsSelect {
            return duplicatedTracks
        } else {
            return uniqueTracks
        }
    }

    public func limitTracks<T: Track>(modeIsSelect: Bool, tracks: [T], mode: LimitMode, amount: Int, unit: LimitUnit) -> [T] {

        switch unit {
        case .tracks:

            switch mode {
            case .first:
                return modeIsSelect ? tracks.prefix(amount).toArray() : tracks.dropFirst(amount).toArray()
            case .last:
                return modeIsSelect ? tracks.suffix(amount).toArray() : tracks.dropLast(amount).toArray()
            case .any:
                let selection = Set(tracks.shuffled().prefix(amount))
                if modeIsSelect {
                    return tracks.filter { selection.contains($0) }.toArray()
                } else {
                    return tracks.filter { !selection.contains($0) }.toArray()
                }
            }

        case .minutes:
            let amount = Double(amount)

            switch mode {
            case .first:

                var minutesCounted = 0.0
                if modeIsSelect {
                    return tracks.prefix(while: {
                        guard minutesCounted < amount else { return false }
                        minutesCounted += (Double($0.durationMs ?? 0) / 1000) / 60
                        return true
                    }).toArray()
                } else {
                    return tracks.drop(while: {
                        guard minutesCounted < amount else { return false }
                        minutesCounted += (Double($0.durationMs ?? 0) / 1000) / 60
                        return true
                    }).toArray()
                }

            case .last:
                var minutesCounted = 0.0
                if modeIsSelect {
                    return tracks
                        .reversed()
                        .prefix(while: {
                            guard minutesCounted < amount else { return false }
                            minutesCounted += (Double($0.durationMs ?? 0) / 1000) / 60
                            return true
                        })
                        .reversed()
                        .toArray()

                } else {
                    return tracks
                        .reversed()
                        .drop(while: {
                            guard minutesCounted < amount else { return false }
                            minutesCounted += (Double($0.durationMs ?? 0) / 1000) / 60
                            return true
                        })
                        .reversed()
                        .toArray()
                }

            case .any:

                var minutesCounted = 0.0
                let selection = tracks
                    .shuffled()
                    .prefix(while: {
                        minutesCounted += (Double($0.durationMs ?? 0) / 1000) / 60
                        return minutesCounted < amount
                    }).toSet()

                if modeIsSelect {
                    return tracks.filter { selection.contains($0) }.toArray()
                } else {
                    return tracks.filter { !selection.contains($0) }.toArray()
                }
            }
        }
        return []
    }
}

private extension Track {
    func matches(title titleRegex: NSRegularExpression?, andArtist artistRegex: NSRegularExpression?) -> Bool {
        var matchTitle: Bool = true
        if let titleRegex = titleRegex {
            matchTitle = title?.contains(regex: titleRegex) ?? true
        }

        var matchArtist = true
        if let artistRegex = artistRegex {
            matchArtist = (artists?.first(where: { artist in artist.name?.contains(regex: artistRegex) == true }) != nil)
        }

        return matchTitle && matchArtist
    }

    func matches(title titleRegex: NSRegularExpression?, orArtist artistRegex: NSRegularExpression?) -> Bool {
        if let titleRegex = titleRegex,
            title?.contains(regex: titleRegex) == true {
            return true
        }

        if let artistRegex = artistRegex,
            artists?.first(where: { artist in artist.name?.contains(regex: artistRegex) == true }) != nil {
            return true
        }

        return false
    }
}
