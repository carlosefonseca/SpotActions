//
//  UserManagerTests.swift
//

import XCTest
import Combine
@testable import CEFSpotifyCore
@testable import CEFSpotifyDoubles

class UserManagerTests: XCTestCase {

    let testUser1: UserJSON = {
        var testUser = UserJSON()
        testUser.id = "1"
        testUser.display_name = "Test User 1"
        return testUser
    }()

    var authManager: FakeSpotifyAuthManager!
    var gateway: FakeSpotifyUserProfileGateway!
    var manager: UserManagerImplementation!
    var bag = Set<AnyCancellable>()

    private func setup(loggedIn: Bool = false) {
        if loggedIn {
            authManager = FakeSpotifyAuthManager(initialState: .loggedIn(token: TokenResponse()))
        } else {
            authManager = FakeSpotifyAuthManager(initialState: .notLoggedIn)
        }
        gateway = FakeSpotifyUserProfileGateway()
        gateway.userJson = testUser1
        manager = UserManagerImplementation(auth: authManager, gateway: gateway)
    }

    override func setUp() {
        bag.removeAll()
    }

    func test_load_user_on_login() {
        setup()

        let ex = expectation(description: "value")

        ex.expectedFulfillmentCount = 2

        var values = [UserJSON?]()

        manager.userPublisher.sink { value in
            print("test - manager.userPublisher: \(value?.description ?? "nil")")
            values.append(value)
            ex.fulfill()
        }.store(in: &bag)

        authManager.login()

        waitForExpectations(timeout: 1)
        XCTAssertEqual(values, [nil, testUser1])
    }

    func test_load_user_on_login2() {
        setup(loggedIn: true)

        let ex = expectation(description: "value")
        ex.expectedFulfillmentCount = 1

        var values = [UserJSON?]()

//        authManager.login()


        manager.userPublisher.sink { value in
            print("test - manager.userPublisher: \(value?.description ?? "nil")")
            values.append(value)
            ex.fulfill()
        }.store(in: &bag)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(values, [testUser1])
    }

    func test_clear_user_on_logout() {
        setup()

        let ex = expectation(description: "value")

        ex.expectedFulfillmentCount = 3

        var values = [UserJSON?]()

        manager.userPublisher.sink { value in
            values.append(value)
            ex.fulfill()
        }.store(in: &bag)

        authManager.login()
        authManager.logout()

        waitForExpectations(timeout: 1)
        XCTAssertEqual(values, [nil, testUser1, nil])
    }
}
