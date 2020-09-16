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

    let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        return jsonEncoder
    }()

    override func setUp() {
        dummyTokenResponse.accessToken = "access_token"
        dummyTokenResponse.refreshToken = "refresh_token"

        bag.removeAll()
        auth = FakeSpotifyAuthManager(initialState: .loggedIn(token: dummyTokenResponse))
        requester = FakeUrlRequester()
        requestManager = AuthenticatedSpotifyRequestManager(auth: auth, requester: requester)
    }

    struct TestData: Codable, Equatable {
        var field = "abc"
    }

    func test_GIVEN_logged_in_WHEN_request_THEN_success() {

        let finishedExpectation = expectation(description: "finished")
        var output: Data?

        let expectedData = try! jsonEncoder.encode(TokenResponse())
        requester.responses.append(.success(expectedData))


        let request = URLRequest(url: URL(string: "http://example.com/abc")!)
        requestManager.execute(urlRequest: request)
            .print("test_login")
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { (value: Data) in
                output = value
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(output, expectedData)
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
            } receiveValue: { (_: Data) in
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

        let expectedData = try! jsonEncoder.encode(TestData())
        requester.responses.append(.success(expectedData))

        requester.responses.append(.failure(UrlRequesterError.apiError(response: unauthorizedResponse, data: "puff".data(using: .utf8)!)))
        auth.refreshTokenResponse = Result.success(dummyTokenResponse)

        let finishedExpectation = expectation(description: "finished")
        var output: Data?

        let request = URLRequest(url: url)
        requestManager.execute(urlRequest: request)
            .print("test_login")
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { (value: Data) in
                output = value
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(output, expectedData)
    }
}
