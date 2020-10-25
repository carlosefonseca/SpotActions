//
// TrackMixerServiceTests.swift
//

import Foundation
import XCTest
import Combine
@testable import CEFSpotifyCore
@testable import CEFSpotifyDoubles

struct TestArtist: Artist, Equatable, Hashable {
    var id: SpotifyID

    var name: String?

    var uri: String?

    init(index: Int) {
        id = "\(index)"
        uri = "artist:\(index)"
        name = "Artist \(index)"
    }
}

struct TestTrack: Track, Equatable, Hashable {
    var id: SpotifyID
    var uri: String?
    var title: String?
    var artists: [TestArtist]?

    var durationMs: Int?

    var externalIdsStr: [String]?

    var linkedTrackId: String?

    var description: String { "TestTrack(\(id))" }

    var artistIds: [SpotifyID] = []
    var artistNames: [String] = []

    var albumName: String?
    var albumArtUrl: URL?
    var albumArtWidth: Int?
    var albumArtHeight: Int?

    init(set: Int, index: Int, artist: TestArtist) {
        id = "\(set)\(index)"
        uri = "track:\(id)"
        title = "Track \(id)"
        artists = [artist]
        durationMs = 60_000
    }
}

class TrackMixerServiceTests: XCTestCase {

    var mixerService: TrackMixerService!

    var fakePlaylistsManager: FakePlaylistsManager!

    var bag = Set<AnyCancellable>()

    override func setUp() {
        fakePlaylistsManager = FakePlaylistsManager()
        mixerService = TrackMixerServiceImplementation(playlistsManager: fakePlaylistsManager)
    }

    let trackSet1 = (1...3).map { i in TestTrack(set: 10, index: i, artist: TestArtist(index: i)) }
    let trackSet2 = (1...3).map { i in TestTrack(set: 20, index: i, artist: TestArtist(index: i)) }
    let trackSet3 = (1...3).map { i in TestTrack(set: 30, index: i, artist: TestArtist(index: i)) }

    func test_concat() {
        let finishedExpectation = expectation(description: "finished")
        var output: [Track]?

        mixerService.mix(trackSets: [trackSet1, trackSet2, trackSet3], mixMode: MixMode.concat)
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { value in
                output = value
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        let ids = output?.map { $0.id }

        let expected = ["101", "102", "103", "201", "202", "203", "301", "302", "303"]

        XCTAssertEqual(ids, expected)
    }

    func test_mix() {
        let finishedExpectation = expectation(description: "finished")
        var output: [Track]?

        mixerService.mix(trackSets: [trackSet1, trackSet2, trackSet3], mixMode: .alternate)
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { value in
                output = value
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        let ids = output?.map { $0.id }

        let expected = ["101", "201", "301", "102", "202", "302", "103", "203", "303"]

        XCTAssertEqual(ids, expected)
    }

    func test_mix_shuffled() {
        let finishedExpectation = expectation(description: "finished")
        var output: [Track]?

        var ids: [String]
        let notExpected1 = ["101", "102", "103", "201", "202", "203", "301", "302", "303"]
        let notExpected2 = ["101", "201", "301", "102", "202", "302", "103", "203", "303"]

        repeat {
            mixerService.mix(trackSets: [trackSet1, trackSet2, trackSet3], mixMode: .mix)
                .sink { completion in
                    finishedExpectation.fulfill()
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }
                } receiveValue: { value in
                    output = value
                }.store(in: &bag)

            waitForExpectations(timeout: 1)

            ids = output?.map { $0.id } ?? []

        } while ids == notExpected1 || ids == notExpected2

        XCTAssertEqual(ids == notExpected1, false)
        XCTAssertEqual(ids == notExpected2, false)
    }
}
