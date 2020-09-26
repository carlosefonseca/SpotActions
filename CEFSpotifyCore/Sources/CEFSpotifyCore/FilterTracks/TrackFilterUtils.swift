//
// TrackFilterUtils.swift
//

import Foundation

class TrackFilterUtils {

//    class func allIdsForTracks<T: Track>(tracks: [T]) -> Set<String> {
//        let otherIds = Set(tracks.compactMap { (track) -> String? in track.id })
//        let linkedIds = Set(tracks.compactMap { track in track.linkedTrackId })
//        return otherIds.union(linkedIds)
//    }
}

extension Track {
    func matches(externalIds: [String]) -> Bool {
        return (self.externalIdsStr ?? []).first(where: { externalIds.contains($0) }) != nil
    }
}

extension Collection where Iterator.Element: Track {
    func trackIds() -> Set<SpotifyID> {
        let ids = Set(self.compactMap { (track) -> SpotifyID? in track.id })
        let linkedIds = Set(self.compactMap { (track) -> SpotifyID? in track.linkedTrackId })
        return ids.union(linkedIds)
    }
}
