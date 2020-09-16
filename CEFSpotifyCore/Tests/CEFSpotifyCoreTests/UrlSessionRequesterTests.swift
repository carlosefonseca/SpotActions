//
// UrlSessionRequesterTests.swift
//

import Foundation
import CEFSpotifyCore
import XCTest
import Combine

class UrlSessionRequesterTests: XCTestCase {
    struct TestData: Codable, Equatable {
        var slideshow: Slideshow
    }

    struct Slideshow: Codable, Equatable {
        var author: String
        var date: String
        var title: String
        var slides: [Slide]
    }

    struct Slide: Codable, Equatable {
        var title: String
        var type: String
        var items: [String]?
    }

    var bag = Set<AnyCancellable>()

    let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()

    override func setUp() {
        super.setUp()
        bag.removeAll()
    }

    func test_successful_request() {
        let requestExpectation = expectation(description: "request")
        var output: TestData?

        let slides = [
            Slide(title: "Wake up to WonderWidgets!", type: "all"),
            Slide(title: "Overview", type: "all", items: [
                "Why <em>WonderWidgets</em> are great",
                "Who <em>buys</em> WonderWidgets"
            ])
        ]

        let expected = TestData(slideshow:
            Slideshow(author: "Yours Truly",
                      date: "date of publication",
                      title: "Sample Slide Show",
                      slides: slides))

        let request = URLRequest(url: URL(string: "https://httpbin.org/json")!)
        UrlSessionRequester()
            .request(urlRequest: request)
            .decode(type: TestData.self, decoder: jsonDecoder)
            .sink { completion in
                print(completion)
                requestExpectation.fulfill()
            } receiveValue: { (value: TestData) in
                print(value)
                output = value
            }.store(in: &bag)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(output, expected)
    }

    func test_error_unauthorized() {
        let requestExpectation = expectation(description: "request")
        let valueExpectation = expectation(description: "value")
        valueExpectation.isInverted = true

        var output: Subscribers.Completion<UrlRequesterError>?
//        var expected = Subscribers.Completion<UrlRequesterError>.failure(UrlRequesterError.apiError(response: <#T##HTTPURLResponse#>, data: <#T##Data#>))

        let request = URLRequest(url: URL(string: "https://httpbin.org/status/401")!)

        UrlSessionRequester()
            .request(urlRequest: request)
            .sink { completion in
                print(completion)
                output = completion
                requestExpectation.fulfill()
            } receiveValue: { (value: Data) in
                print(value)
                valueExpectation.fulfill()
            }.store(in: &bag)

        waitForExpectations(timeout: 10)

        guard
            let completionOutput = output,
            case Subscribers.Completion<UrlRequesterError>.failure(let error) = completionOutput,
            case .apiError(let response, _) = error else {
            XCTFail()
            return
        }

        XCTAssertEqual(response.type, .unauthorized)
    }
}
