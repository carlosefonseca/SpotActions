//
// TrackFilterServiceTests.swift
//

import Foundation
import XCTest
@testable import CEFSpotifyCore
import CEFSpotifyDoubles

class TrackFilterServiceTests: XCTestCase {

    let largeSet = (1..<1000).map {
        TrackJSON(artists: [ArtistJSON(id: "aid\($0 % 20)", name: "Artist\($0 % 100)")],
                  externalIds: ["eid": "eid\($0)"],
                  id: "id\($0)",
                  linkedFrom: TrackLinkJSON(id: "lid\($0)"),
                  name: "Track\($0)")
    }

    let t_ID_567 = TrackJSON(id: "id567")
    let t_EID_789 = TrackJSON(externalIds: ["eid": "eid789"], id: "XXX")
    let t_LID_987 = TrackJSON(id: "lid987")
    let t_LID_345 = TrackJSON(id: "XXX", linkedFrom: TrackLinkJSON(id: "id345"))
    let t_XXX = TrackJSON(id: "XXX")

    var fakePlaylistsManager: FakePlaylistsManager!
    var service: TrackFilterService!

    override func setUp() {
        fakePlaylistsManager = FakePlaylistsManager()
        service = TrackFilterServiceImplementation(playlistsManager: fakePlaylistsManager)
    }

    // MARK: - Title

    func test_filter_by_single_title_plain_match_single() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: ["Track123"],
                                                 artists: nil,
                                                 and: false,
                                                 isRegex: false)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        XCTAssertEqual(ids, ["id123"])
    }

    func test_filter_by_single_title_plain_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: ["Track12"],
                                                 artists: nil,
                                                 and: false,
                                                 isRegex: false)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id12",
                           "id120",
                           "id121",
                           "id122",
                           "id123",
                           "id124",
                           "id125",
                           "id126",
                           "id127",
                           "id128",
                           "id129"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_multiple_title_plain_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: ["Track123", "Track321"],
                                                 artists: nil,
                                                 and: false,
                                                 isRegex: false)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id123",
                           "id321"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_single_title_regex_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: ["Track12[36]?$"],
                                                 artists: nil,
                                                 and: false,
                                                 isRegex: true)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id12",
                           "id123",
                           "id126"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_multiple_title_regex_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: ["Track12[36]$", "Track[12][12]$"],
                                                 artists: nil,
                                                 and: false,
                                                 isRegex: true)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id11",
                           "id12",
                           "id21",
                           "id22",
                           "id123",
                           "id126"]

        XCTAssertEqual(ids, expectation)
    }

    // MARK: - Artist

    func test_filter_by_single_artist_plain_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: nil,
                                                 artists: ["Artist30"],
                                                 and: false,
                                                 isRegex: false)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id30", "id130", "id230", "id330", "id430", "id530", "id630", "id730", "id830", "id930"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_multiple_artist_plain_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: nil,
                                                 artists: ["Artist20", "Artist30"],
                                                 and: false,
                                                 isRegex: false)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id20",
                           "id30",
                           "id120",
                           "id130",
                           "id220",
                           "id230",
                           "id320",
                           "id330",
                           "id420",
                           "id430",
                           "id520",
                           "id530",
                           "id620",
                           "id630",
                           "id720",
                           "id730",
                           "id820",
                           "id830",
                           "id920",
                           "id930"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_single_artist_regex_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: nil,
                                                 artists: ["Artist1[36]?$"],
                                                 and: false,
                                                 isRegex: true)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id1", "id13", "id16",
                           "id101", "id113", "id116",
                           "id201", "id213", "id216",
                           "id301", "id313", "id316",
                           "id401", "id413", "id416",
                           "id501", "id513", "id516",
                           "id601", "id613", "id616",
                           "id701", "id713", "id716",
                           "id801", "id813", "id816",
                           "id901", "id913", "id916"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_multiple_artist_regex_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: nil,
                                                 artists: ["Artist[36]$", "Artist19$"],
                                                 and: false,
                                                 isRegex: true)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id3", "id6", "id19",
                           "id103", "id106", "id119",
                           "id203", "id206", "id219",
                           "id303", "id306", "id319",
                           "id403", "id406", "id419",
                           "id503", "id506", "id519",
                           "id603", "id606", "id619",
                           "id703", "id706", "id719",
                           "id803", "id806", "id819",
                           "id903", "id906", "id919"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_title_and_artist_plain_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: ["Track101", "Track202"],
                                                 artists: ["Artist1"],
                                                 and: true,
                                                 isRegex: false)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id101"]

        XCTAssertEqual(ids, expectation)
    }

    func test_filter_by_title_or_artist_plain_match_multiple() {
        let output = service.filterByTitleArtist(modeIsSelect: true,
                                                 tracks: largeSet,
                                                 titles: ["Track101", "Track202"],
                                                 artists: ["Artist1"],
                                                 and: false,
                                                 isRegex: false)

        guard case .success(let value) = output else { XCTFail(); return }

        let ids = value.map { $0.id }

        let expectation = ["id1",
                           "id101",
                           "id201",
                           "id202",
                           "id301",
                           "id401",
                           "id501",
                           "id601",
                           "id701",
                           "id801",
                           "id901"]

        XCTAssertEqual(ids, expectation)
    }
}
