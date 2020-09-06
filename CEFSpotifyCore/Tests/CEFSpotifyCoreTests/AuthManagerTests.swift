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
    var fakeRequester: FakeUrlRequester!

    var bag = Set<AnyCancellable>()

    override func setUp() {
        bag.removeAll()
        credentialStore = FakeCredentialStore()
        fakeRequester = FakeUrlRequester()
    }

    func test_when_successful_login_then_state_is_logged_in() {

        webAuth = FakeWebAuth(
            loginResult: .success(URL(string: "https://example.com/?code=token_code")!),
            requestResult: .success(TokenResponse())
        )

        fakeRequester.responses.append(Result.success(TokenResponse()))

        authManager = SpotifyAuthManagerImplementation(webAuthManager: webAuth,
                                                       credentialStore: credentialStore,
                                                       requester: fakeRequester)

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
                                                       credentialStore: credentialStore,
                                                       requester: FakeUrlRequester())

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

    func test_createRefreshTokenUrlRequest() {
        webAuth = FakeWebAuth(
            loginResult: .success(URL(string: "https://example.com/?code=token_code")!),
            requestResult: .success(TokenResponse())
        )

        var x = TokenResponse()
        x.access_token = "access_token1"
        x.expires_in = 0
        x.refresh_token = "refresh_token"
        x.scope = "scope"

        let encodedValue = try! JSONEncoder().encode(x)

        try! credentialStore.set(value: encodedValue, account: "defaultAccount")

        authManager = SpotifyAuthManagerImplementation(webAuthManager: webAuth,
                                                       credentialStore: credentialStore,
                                                       requester: fakeRequester)

        var output: URLRequest?

        authManager.createRefreshTokenUrlRequest().sink { completion in
            guard case .finished = completion else {
                XCTFail()
                return
            }
        } receiveValue: { value in
            output = value
        }.store(in: &bag)

        let authHeader = authManager.authHeader!
        XCTAssertEqual(output?.httpMethod, "POST")
        XCTAssertEqual(output?.httpBody, "grant_type=refresh_token&refresh_token=refresh_token".data(using: .utf8))
        XCTAssertEqual(output?.allHTTPHeaderFields?["Authorization"], "Basic \(authHeader)")
    }

    func test_refreshToken() {
        webAuth = FakeWebAuth(
            loginResult: .success(URL(string: "https://example.com/?code=token_code")!),
            requestResult: .success(TokenResponse())
        )

        var oldToken = TokenResponse()
        oldToken.access_token = "access_token1"
        oldToken.expires_in = 0
        oldToken.refresh_token = "refresh_token"
        oldToken.scope = "scope"
        let oldTokenAsData = try! JSONEncoder().encode(oldToken)
        try! credentialStore.set(value: oldTokenAsData, account: "defaultAccount")

        var newToken = TokenResponse()
        newToken.access_token = "access_token2"
        newToken.expires_in = 0
        newToken.refresh_token = "refresh_token"
        newToken.scope = "scope"

        fakeRequester.responses.append(Result.success(newToken))

        authManager = SpotifyAuthManagerImplementation(webAuthManager: webAuth,
                                                       credentialStore: credentialStore,
                                                       requester: fakeRequester)

        var output: TokenResponse?

        let finishExpectation = expectation(description: "finished")

        authManager.refreshToken().sink { completion in
            finishExpectation.fulfill()
            guard case .finished = completion else {
                XCTFail()
                return
            }
        } receiveValue: { value in
            output = value
        }.store(in: &bag)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(output, newToken)

        XCTAssertEqual(authManager.state, .loggedIn(token: newToken))
    }
}
