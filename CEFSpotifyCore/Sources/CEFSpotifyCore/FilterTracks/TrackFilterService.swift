//
// TrackFilterService.swift
//

import Foundation
import Combine

public protocol TrackFilterService {
    func filterByTitleArtist<T: Track>(modeIsSelect: Bool, tracks: [T], titles: [String]?, artists: [String]?, and: Bool, isRegex: Bool) -> Result<[T], ErrorMessage>
    func existsInPlaylist<T: Track>(modeIsSelect: Bool, tracks: [T], otherPlaylistId: String) -> AnyPublisher<[T], ErrorMessage>
    func filterTracksWithOtherTracks<T1: Track, T2: Track>(modeIsSelect: Bool, tracks: [T1], otherTracks: [T2]) -> [T1]
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
                TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: modeIsSelect, tracks: tracks, otherTracks: otherPlaylistTracks)
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
