//
// File.swift
//

import Foundation
import XCTest
@testable import CEFSpotifyCore

class SpotifyURITests: XCTestCase {
    func test_track_uri() {
        let uri: SpotifyURI = "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"

        XCTAssertEqual(uri.id, "6rqhFgbbKwnb9MLmUQDhG6")
        XCTAssertEqual(uri.category, "track")
    }

    func test_playlist_uri() {
        let uri: SpotifyURI = "spotify:playlist:1mXdk5YLdvsqcFPYUqbd8f"

        XCTAssertEqual(uri.id, "1mXdk5YLdvsqcFPYUqbd8f")
        XCTAssertEqual(uri.category, "playlist")
    }

    func test_user_uri() {
        let uri: SpotifyURI = "spotify:user:carlosefonseca"

        XCTAssertEqual(uri.id, "carlosefonseca")
        XCTAssertEqual(uri.category, "user")
    }

    func test_artist_uri() {
        let uri: SpotifyURI = "spotify:artist:0grdhNhiRLFBaFVyybqsj6"

        XCTAssertEqual(uri.id, "0grdhNhiRLFBaFVyybqsj6")
        XCTAssertEqual(uri.category, "artist")
    }

    func test_album_uri() {
        let uri: SpotifyURI = "spotify:album:4baH7jTFRxpa36d0hxi0yK"

        XCTAssertEqual(uri.id, "4baH7jTFRxpa36d0hxi0yK")
        XCTAssertEqual(uri.category, "album")
    }


    func test_playlist_with_user() {
        let uri = "spotify:user:carlosefonseca:playlist:20IsQZexWUDfjim8Xn3g52"
        XCTAssertEqual(uri.id, "20IsQZexWUDfjim8Xn3g52")
        XCTAssertEqual(uri.category, "playlist")
    }
}
