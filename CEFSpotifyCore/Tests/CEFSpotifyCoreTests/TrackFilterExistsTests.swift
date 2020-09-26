//
// TrackFilterExistsTests.swift
//

import Foundation
import XCTest
@testable import CEFSpotifyCore

class TrackFilterExistsTests: XCTestCase {

    var t1 = TrackJSON(externalIds: ["eid": "eid1"], id: "tid1", linkedFrom: TrackLinkJSON(id: "lid1"), name: "Track1")
    var t2 = TrackJSON(externalIds: ["eid": "eid2"], id: "tid2", linkedFrom: TrackLinkJSON(id: "lid2"), name: "Track2")
    var t3 = TrackJSON(externalIds: ["eid": "eid3"], id: "tid3", linkedFrom: TrackLinkJSON(id: "lid3"), name: "Track3")
    var t4 = TrackJSON(externalIds: ["eid": "eid4"], id: "tid4", linkedFrom: TrackLinkJSON(id: "lid4"), name: "Track4")
    var t5 = TrackJSON(externalIds: ["eid": "eid5"], id: "tid5", linkedFrom: TrackLinkJSON(id: "lid5"), name: "Track5")
    var t6 = TrackJSON(externalIds: ["eid": "eid6"], id: "tid6", linkedFrom: TrackLinkJSON(id: "lid6"), name: "Track6")

    var lt1 = TrackJSON(externalIds: ["eid": "eidX1"], id: "tidXX1", linkedFrom: TrackLinkJSON(id: "lid1"), name: "Track1")
    var lt2 = TrackJSON(externalIds: ["eid": "eid2"], id: "tidXX2", linkedFrom: TrackLinkJSON(id: "lidXX2"), name: "Track2")

    let largeSet = (1..<1000).map {
        TrackJSON(externalIds: ["eid": "eid\($0)"], id: "id\($0)", linkedFrom: TrackLinkJSON(id: "lid\($0)"))
    }

    let t_ID_567 = TrackJSON(id: "id567")
    let t_EID_789 = TrackJSON(externalIds: ["eid": "eid789"], id: "XXX")
    let t_LID_987 = TrackJSON(id: "lid987")
    let t_LID_345 = TrackJSON(id: "XXX", linkedFrom: TrackLinkJSON(id: "id345"))
    let t_XXX = TrackJSON(id: "XXX")

    override func setUp() {}

    func test_select_all() {
        let set1 = [t1, t2, t3, t4, t5, t6]
        let set2 = [t1, t2, t3, t4, t5, t6]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: true, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, set1)
    }

    func test_select_none() {
        let set1 = [t1, t2, t3]
        let set2 = [t4, t5, t6]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: true, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [])
    }

    func test_select_partial() {
        let set1 = [t1, t2, t3, t4, t5, t6]
        let set2 = [t4, t5, t6]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: true, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, set2)
    }

    func test_matches_two_different_tracks_by_linked_track() {
        let set1 = [t1, t2]
        let set2 = [lt1]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: true, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [t1])
    }

    func test_matches_two_different_tracks_by_external_id() {
        let set1 = [t1, t2]
        let set2 = [lt2]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: true, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [t2])
    }

    func test_select_large() {
        let set1 = [t_ID_567, t_EID_789, t_LID_987, t_LID_345, t_XXX]
        let set2 = largeSet

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: true, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [t_ID_567, t_EID_789, t_LID_987, t_LID_345])
    }

    // MARK: - REJECT

    func test_rejects_tracks_that_exist_in_other_set() {
        let set1 = [t1, t2, t3, t4, t5, t6]
        let set2 = [t1, t2, t3, t4, t5]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: false, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [t6])
    }

    func test_rejects_tracks_that_matches_by_linked_track() {
        let set1 = [t1, t2]
        let set2 = [lt1]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: false, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [t2])
    }

    func test_rejects_tracks_that_matches_two_different_tracks_by_external_id() {
        let set1 = [t1, t2]
        let set2 = [lt2]

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: false, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [t1])
    }

    func test_reject_large() {
        let set1 = [t_ID_567, t_EID_789, t_LID_987, t_LID_345, t_XXX]
        let set2 = largeSet

        let output = TrackFilterExists().filterTracksWithOtherTracks(modeIsSelect: false, tracks: set1, otherTracks: set2)
        XCTAssertEqual(output, [t_XXX])
    }
}
