//
// AuthManagerTests.swift
//

import Foundation
import Combine
import XCTest
@testable import CEFSpotifyCore
@testable import CEFSpotifyDoubles

class AuthManagerTests: XCTestCase {

    var webAuth: FakeWebAuth!
    var credentialStore: FakeCredentialStore!
    var authManager: SpotifyAuthManagerImplementation!

    var bag = Set<AnyCancellable>()

    override func setUp() {
        bag.removeAll()
        credentialStore = FakeCredentialStore()
    }

    func test_when_successful_login_then_state_is_logged_in() {

        webAuth = FakeWebAuth(
            loginResult: .success(URL(string: "https://example.com/?code=token_code")!),
            requestResult: .success(TokenResponse())
        )

        authManager = SpotifyAuthManagerImplementation(webAuthManager: webAuth,
                                                       credentialStore: credentialStore)


        var values = [AuthState]()

        let finishExpectation = expectation(description: "finished")

        authManager.statePublisher
            .prefix(2)
            .sink(receiveCompletion: { _ in finishExpectation.fulfill() },
                  receiveValue: { values.append($0) })
            .store(in: &bag)

        authManager.login()
        waitForExpectations(timeout: 1)

        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0], .notLoggedIn)
        XCTAssertEqual(values[1], .loggedIn(token: TokenResponse()))
    }

    func test_when_failed_login_then_state_is_error() {
        webAuth = FakeWebAuth(
            loginResult: .failure(URLError(URLError.badServerResponse)),
            requestResult: .failure(URLError(URLError.badServerResponse))
        )

        authManager = SpotifyAuthManagerImplementation(webAuthManager: webAuth,
        credentialStore: credentialStore)

        let finishExpectation = expectation(description: "finished")

        var values = [AuthState]()

        authManager.statePublisher
            .prefix(2)
            .sink(receiveCompletion: { _ in finishExpectation.fulfill() },
                  receiveValue: { values.append($0) })
            .store(in: &bag)

        authManager.login()
        waitForExpectations(timeout: 1)

        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0], .notLoggedIn)
        XCTAssertEqual(values[1], .error(URLError(.badServerResponse).localizedDescription))
        XCTAssertEqual(values.count, 2)

    }
}
