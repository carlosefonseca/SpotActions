//
//  GetUserProfileHandlerTests.swift
//  SpotActionsTests
//
//  Created by carlos.fonseca on 25/08/2020.
//

import XCTest
@testable import SpotActions
import CEFSpotifyCore
import CEFSpotifyDoubles

class GetUserProfileHandlerTests: XCTestCase {

    var authManager: FakeSpotifyAuthManager!
    var userManager: FakeUserManager!
    var handler: GetUserProfileHandler!

    var testUser: UserJSON!
    var testIntentUser: User!

    override func setUpWithError() throws {
        testUser = UserJSON()
        testUser.id = "1"
        testUser.display_name = "Test User 1"

        testIntentUser = User(from: testUser)

        userManager = FakeUserManager(fakeUser: testUser)
        authManager = FakeSpotifyAuthManager(initialState: .loggedIn(token: TokenResponse()))

        handler = GetUserProfileHandler(auth: authManager,
                                        userManager: userManager)
    }

    func test_user_is_returned() throws {

        let completion = expectation(description: "completionCalled")

        var response: GetUserProfileIntentResponse?

        handler.handle(intent: GetUserProfileIntent()) { r in
            response = r
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(response != nil, true)
        XCTAssertEqual(response?.result, testIntentUser)
        XCTAssertEqual(response?.error, nil)
    }
}
