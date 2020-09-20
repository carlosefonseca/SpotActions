//
// GetUserPlaylistsHandlerTests.swift
//

import XCTest
@testable import SpotActions
import CEFSpotifyCore
import CEFSpotifyDoubles

class GetUserPlaylistsHandlerTests: XCTestCase {
    var authManager: FakeSpotifyAuthManager!
    var userManager: FakeUserManager!

    var fakeGateway: FakeSpotifyPlaylistsGateway!
    var playlistsManager: PlaylistsManagerImplementation!

    var handler: GetUserPlaylistsHandler!

    var testUser: UserJSON!

    override func setUp() {
        testUser = UserJSON()
        testUser.id = "1"
        testUser.displayName = "Test User 1"

        authManager = FakeSpotifyAuthManager(initialState: .loggedIn(token: TokenResponse()))
        userManager = FakeUserManager(fakeUser: testUser)

        fakeGateway = FakeSpotifyPlaylistsGateway()
        playlistsManager = PlaylistsManagerImplementation(auth: authManager, gateway: fakeGateway)

        handler = GetUserPlaylistsHandler(
            auth: authManager,
            userManager: userManager,
            playlistsManager: playlistsManager)
    }

    func test_get_single_page_user_playlists() {
        let expected = [
            INPlaylist(identifier: "p1", display: "P1"),
            INPlaylist(identifier: "p2", display: "P2"),
        ]

        let r = PagedPlaylistsJSON(
            items: [
                PlaylistJSON(id: "p1", name: "P1"),
                PlaylistJSON(id: "p2", name: "P2"),
            ], total: 2)

        fakeGateway.userPlaylistsResponses.append(.success(r))

        let completionExpectation = expectation(description: "completionCalled")

        var response: GetUserPlaylistsIntentResponse?

        handler.handle(intent: GetUserPlaylistsIntent()) { completion in
            response = completion
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(response?.result, expected)
        XCTAssertEqual(response?.error, nil)
    }

    func test_get_multi_page_user_playlists() {
        let expected = [
            INPlaylist(identifier: "p1", display: "P1"),
            INPlaylist(identifier: "p2", display: "P2"),
            INPlaylist(identifier: "p3", display: "P3"),
            INPlaylist(identifier: "p4", display: "P4"),
        ]

        let r1 = PagedPlaylistsJSON(
            items: [
                PlaylistJSON(id: "p1", name: "P1"),
            ],
            next: "page2",
            total: 4)

        let r2 = PagedPlaylistsJSON(
            items: [
                PlaylistJSON(id: "p2", name: "P2"),
                PlaylistJSON(id: "p3", name: "P3"),
            ],
            next: "page3",
            total: 2)

        let r3 = PagedPlaylistsJSON(
            items: [
                PlaylistJSON(id: "p4", name: "P4"),
            ], total: 2)

        fakeGateway.userPlaylistsResponses.append(.success(r1))
        fakeGateway.nextUserPlaylistsResponses.append(contentsOf: [.success(r2), .success(r3)])

        let completionExpectation = expectation(description: "completionCalled")

        var response: GetUserPlaylistsIntentResponse?

        handler.handle(intent: GetUserPlaylistsIntent()) { completion in
            response = completion
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(response?.result, expected)
        XCTAssertEqual(response?.error, nil)
    }
}
