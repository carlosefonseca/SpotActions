//
// TrackFilterExists.swift
//

import Foundation
import Combine

public class TrackFilterExists {

    public init() {}

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
