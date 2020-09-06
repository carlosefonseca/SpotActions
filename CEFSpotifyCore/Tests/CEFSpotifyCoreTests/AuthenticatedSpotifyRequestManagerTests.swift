//
// AuthenticatedSpotifyRequestManagerTests.swift
//

import Foundation
import Combine
import XCTest
@testable import CEFSpotifyCore
import CEFSpotifyDoubles

class AuthenticatedSpotifyRequestManagerTests: XCTestCase {

    var auth: FakeSpotifyAuthManager!
    var requester: FakeUrlRequester!
    var requestManager: AuthenticatedSpotifyRequestManager!
    var bag = Set<AnyCancellable>()
    var dummyTokenResponse = TokenResponse()

    override func setUp() {
        dummyTokenResponse.access_token = "access_token"
        dummyTokenResponse.refresh_token = "refresh_token"

        bag.removeAll()
        auth = FakeSpotifyAuthManager(initialState: .loggedIn(token: dummyTokenResponse))
        requester = FakeUrlRequester()
        requester.responses.append(.success(TestData()))
        requestManager = AuthenticatedSpotifyRequestManager(auth: auth, requester: requester)
    }

    struct TestData: Codable, Equatable {
        var field = "abc"
    }

    func test_GIVEN_logged_in_WHEN_request_THEN_success() {

        let finishedExpectation = expectation(description: "finished")
        var output: TestData?

        let request = URLRequest(url: URL(string: "http://example.com/abc")!)
        requestManager.execute(urlRequest: request)
            .print("test_login")
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { (value: TestData) in
                output = value
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(output, TestData())
    }

    func test_GIVEN_not_logged_in_WHEN_request_THEN_fail_with_noLogin() {

        auth.state = .notLoggedIn

        let finishedExpectation = expectation(description: "finished")
        var output: SpotifyRequestError?

        let request = URLRequest(url: URL(string: "http://example.com/abc")!)
        requestManager.execute(urlRequest: request)
            .print("test_login")
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .failure(let error) = completion else {
                    XCTFail()
                    return
                }
                output = error as? SpotifyRequestError
            } receiveValue: { (_: TestData) in
                XCTFail()
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        switch output {
        case .noLogin:
            // Success
            break
        default:
            XCTFail()
        }
    }

    func test_GIVEN_login_expired_WHEN_request_THEN_success() {
        let url = URL(string: "http://example.com/abc")!
        let unauthorizedResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!

        requester.responses.append(.failure(UrlRequesterError.apiError(response: unauthorizedResponse, data: "puff".data(using: .utf8)!)))
        auth.refreshTokenResponse = Result.success(dummyTokenResponse)

        let finishedExpectation = expectation(description: "finished")
        var output: TestData?

        let request = URLRequest(url: url)
        requestManager.execute(urlRequest: request)
            .print("test_login")
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { (value: TestData) in
                output = value
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(output, TestData())
    }
}
