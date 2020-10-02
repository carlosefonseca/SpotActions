//
// FilterTracksHandlerTests.swift
//

import Foundation
import XCTest
@testable import SpotActions
@testable import CEFSpotifyCore
import CEFSpotifyDoubles

// COMPONENT TESTS (ALL REAL EXCEPT GATEWAY)

class FilterTracksHandlerTests: XCTestCase {

    var authManager: FakeSpotifyAuthManager!
    var userManager: FakeUserManager!
    var fakeSpotifyPlaylistsGateway: FakeSpotifyPlaylistsGateway!

    var playlistsManager: PlaylistsManager!
    var trackFilterService: TrackFilterService!

    var handler: FilterTracksHandler!

    var testUser: UserJSON!
    var testIntentUser: INUser!

    let largeJSONSet = (1..<1000).map {
        TrackJSON(artists: [ArtistJSON(id: "aid\($0 % 20)", name: "Artist\($0 % 100)")],
                  durationMs: 90 * 1000,
                  externalIds: ["eid": "eid\($0)"],
                  id: "id\($0)",
                  linkedFrom: TrackLinkJSON(id: "lid\($0)"),
                  name: "Track\($0)",
                  uri: "uri:id\($0)")
    }

    lazy var largeINSet = { largeJSONSet.map { INTrack(from: $0) } }()

    override func setUp() {
        testUser = UserJSON()
        testUser.id = "1"
        testUser.displayName = "Test User 1"

        testIntentUser = INUser(from: testUser)

        userManager = FakeUserManager(fakeUser: testUser)
        authManager = FakeSpotifyAuthManager(initialState: .loggedIn(token: TokenResponse()))

        fakeSpotifyPlaylistsGateway = FakeSpotifyPlaylistsGateway()

        playlistsManager = PlaylistsManagerImplementation(auth: authManager, gateway: fakeSpotifyPlaylistsGateway)

        trackFilterService = TrackFilterServiceImplementation(playlistsManager: playlistsManager)

        handler = FilterTracksHandler(playlistsManager: playlistsManager, trackFilterService: trackFilterService)
    }

    func test_filter_title_artist() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.filter = .titleAndArtist
        intent.tracks = largeINSet
        intent.andTitles = ["Track123"]

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id123"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_exist_in_playlist() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let playlistTracks: PagedTracksJSON = PagedTracksJSON(items: largeJSONSet.map { PageTrackJSON(track: $0) }, total: largeJSONSet.count)
        fakeSpotifyPlaylistsGateway.playlistTracksResponses.append(.success(playlistTracks))

        let trackThatExists = largeINSet.first(where: { $0.id == "id123" })!
        let trackThatDoesNotExist = INTrack(identifier: "id1001", display: "Blah")

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.filter = .existInPlaylist
        intent.tracks = [trackThatExists, trackThatDoesNotExist]
        intent.otherPlaylist = INPlaylist(identifier: "playlist1", display: "Other Playlist")

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id123"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_exist_in_tracks() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let trackThatExists = largeINSet.first(where: { $0.id == "id123" })!
        let trackThatDoesNotExist = INTrack(identifier: "id1001", display: "Blah")

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.filter = .existInTracks
        intent.tracks = [trackThatExists, trackThatDoesNotExist]
        intent.otherTracks = largeINSet

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id123"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_select_duplicated() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let trackThatExists1 = largeINSet.first(where: { $0.id == "id123" })!
        let trackWithSameLinkedId = INTrack(artists: [], externalIds: [], id: "X", linkedTrackId: "id123", name: "Track 123 II")
        let trackThatExists2 = largeINSet.first(where: { $0.id == "id321" })!

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.filter = .dedup
        intent.tracks = [trackThatExists1, trackThatExists2, trackWithSameLinkedId]

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["X"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_reject_duplicated() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let trackThatExists1 = largeINSet.first(where: { $0.id == "id123" })!
        let trackWithSameLinkedId = INTrack(artists: [], externalIds: [], id: "X", linkedTrackId: "id123", name: "Track 123 II")
        let trackThatExists2 = largeINSet.first(where: { $0.id == "id321" })!

        let intent = FilterTracksIntent()
        intent.mode = .reject
        intent.filter = .dedup
        intent.tracks = [trackThatExists1, trackThatExists2, trackWithSameLinkedId]

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id123", "id321"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_select_first_tracks() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .reject
        intent.tracks = Array(largeINSet.prefix(4))
        intent.filter = .limit
        intent.limitMode = .first
        intent.amount = 2
        intent.unit = .tracks

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id3", "id4"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_select_first_minutes() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .first
        intent.amount = 5
        intent.unit = .minutes

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id1", "id2", "id3", "id4"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_select_first_hour() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .first
        intent.amount = 1
        intent.unit = .hours

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTracks = response?.result
        let expectedTracks = Array(largeINSet.prefix(40))

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, expectedTracks.count)
        XCTAssertEqual(resultingTracks, expectedTracks)
        XCTAssertEqual(response?.error, nil)
    }
}
