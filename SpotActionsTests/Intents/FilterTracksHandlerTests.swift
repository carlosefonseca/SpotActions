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
        TrackJSON(artists: [ArtistJSON(id: "aid\($0 % 100)", name: "Artist\($0 % 100)")],
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

    func test_filter_title_and_artist() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.filter = .titleAndArtist
        intent.tracks = largeINSet
        intent.andTitles = ["Track12"]
        intent.andArtists = ["Artist23"]

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

    func test_filter_title_or_artist() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.filter = .titleOrArtist
        intent.tracks = largeINSet
        intent.orTitles = ["Track123"]
        intent.orArtists = ["Artist10"]

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id10", "id110", "id123", "id210", "id310", "id410", "id510", "id610", "id710", "id810", "id910"])
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

        let trackDuplicated = largeINSet.first(where: { $0.id == "id123" })!
        let trackWithSameLinkedId = INTrack(artists: [], externalIds: [], id: "X1", linkedTrackId: "id124", name: "Track 124 II")
        let trackWithSameExtId = INTrack(artists: [], externalIds: [INExternalId(key: "eid", value: "eid125")], id: "X2", linkedTrackId: nil, name: "Track 125 II")

        let artist26 = INArtist(identifier: "aid26", display: "Artist26")
        let trackWithSameName = INTrack(artists: [artist26], externalIds: nil, id: "X3", linkedTrackId: nil, name: "Track126")

        let tracks = largeINSet.filter { $0.id.hasPrefix("id12") } + [trackDuplicated, trackWithSameLinkedId, trackWithSameExtId, trackWithSameName]

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.filter = .dedup
        intent.tracks = tracks

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id123", "X1", "X2", "X3"])
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
        intent.mode = .select
        intent.tracks = largeINSet.prefix(4).toArray()
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
        XCTAssertEqual(resultingTrackIds, ["id1", "id2"])
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_reject_first_tracks() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .reject
        intent.tracks = largeINSet.prefix(4).toArray()
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

    func test_filter_select_last_tracks() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.tracks = largeINSet.prefix(4).toArray()
        intent.filter = .limit
        intent.limitMode = .last
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

    func test_filter_reject_last_tracks() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .reject
        intent.tracks = largeINSet.prefix(4).toArray()
        intent.filter = .limit
        intent.limitMode = .last
        intent.amount = 2
        intent.unit = .tracks

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTrackIds = response?.result?.map { $0.id }

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTrackIds, ["id1", "id2"])
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
        let expectedTracks = largeINSet.prefix(40).toArray()

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, expectedTracks.count)
        XCTAssertEqual(resultingTracks, expectedTracks)
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_reject_first_hour() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .reject
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
        let expectedTracks = largeINSet.dropFirst(40).toArray()

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, expectedTracks.count)
        XCTAssertEqual(resultingTracks, expectedTracks)
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_select_last_hour() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .last
        intent.amount = 1
        intent.unit = .hours

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTracks = response?.result
        let expectedTracks = Array(largeINSet.suffix(40))

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, expectedTracks.count)
        XCTAssertEqual(resultingTracks, expectedTracks)
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_reject_last_hour() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .reject
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .last
        intent.amount = 1
        intent.unit = .hours

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTracks = response?.result
        let expectedTracks = Array(largeINSet.dropLast(40))

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, expectedTracks.count)
        XCTAssertEqual(resultingTracks, expectedTracks)
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_select_any_tracks() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .any
        intent.amount = 10
        intent.unit = .tracks

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTracks = response?.result

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, 10)
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_reject_any_tracks() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .reject
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .any
        intent.amount = 10
        intent.unit = .tracks

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTracks = response?.result

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, largeINSet.count - 10)
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_select_any_minutes() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .select
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .any
        intent.amount = 5
        intent.unit = .minutes

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTracks = response?.result

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, 4)
        XCTAssertEqual(response?.error, nil)
    }

    func test_filter_reject_any_minutes() {
        let completion = expectation(description: "completionCalled")

        var response: FilterTracksIntentResponse?

        let intent = FilterTracksIntent()
        intent.mode = .reject
        intent.tracks = largeINSet
        intent.filter = .limit
        intent.limitMode = .any
        intent.amount = 5
        intent.unit = .minutes

        handler.handle(intent: intent) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        let resultingTracks = response?.result

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(resultingTracks?.count, largeINSet.count - 4)
        XCTAssertEqual(response?.error, nil)
    }
}
