//
// File.swift
//

import Foundation
import XCTest
@testable import CEFSpotifyCore
import CEFSpotifyDoubles
import Combine
import CombineExpectations

class PlayerGatewayTests: XCTestCase {

    var fakeRequestManager: FakeRequestManager!
    var gateway: SpotifyPlayerGatewayImplementation!

    override func setUp() {
        fakeRequestManager = FakeRequestManager()
        gateway = SpotifyPlayerGatewayImplementation(baseURL: URL(string: "/")!,
                                                     requestManager: fakeRequestManager)
    }

    func test_nothing_is_currently_playing() {
        fakeRequestManager.responses.append(.success("".data(using: .utf8)!)) // TODO: ?????

        let publisher = gateway.getCurrentlyPlaying()

        let elements = try? wait(for: publisher.record().elements, timeout: 10)
        let completion = try? wait(for: publisher.record().completion, timeout: 10)

        XCTAssertEqual(elements, nil)
    }

    func test_currently_playing() {
        fakeRequestManager.responses.append(.success(currentlyPlayingSample.data(using: .utf8)!))

        let publisher = gateway.getCurrentlyPlaying()

        let optElements = try? wait(for: publisher.record().elements, timeout: 1)

        guard let elements = optElements else { XCTFail(); return }

        let context: ContextJSON = ContextJSON(uri: "spotify:user:carlosefonseca:playlist:7oorBA7hnNJngmox1JNrGW",
                                               href: "https://api.spotify.com/v1/playlists/7oorBA7hnNJngmox1JNrGW",
                                               externalUrls: ["spotify": "https://open.spotify.com/playlist/7oorBA7hnNJngmox1JNrGW"],
                                               type: "playlist")

        let albumImg1 = ImageJSON(url: "https://i.scdn.co/image/ab67616d0000b273797febe9f06dd027b67a3e64", height: 640, width: 640)
        let albumImg2 = ImageJSON(url: "https://i.scdn.co/image/ab67616d00001e02797febe9f06dd027b67a3e64", height: 300, width: 300)
        let albumImg3 = ImageJSON(url: "https://i.scdn.co/image/ab67616d00004851797febe9f06dd027b67a3e64", height: 64, width: 64)

        let artist = ArtistJSON(externalUrls: ["spotify": "https://open.spotify.com/artist/0C0XlULifJtAgn6ZNCW2eu"],
                                href: "https://api.spotify.com/v1/artists/0C0XlULifJtAgn6ZNCW2eu",
                                id: "0C0XlULifJtAgn6ZNCW2eu",
                                name: "The Killers",
                                type: "artist",
                                uri: "spotify:artist:0C0XlULifJtAgn6ZNCW2eu")

        let album = AlbumJSON(albumGroup: nil,
                              albumType: AlbumTypeJSON.album,
                              artists: [artist],
                              availableMarkets: [],
                              externalUrls: ["spotify": "https://open.spotify.com/album/6TJmQnO44YE5BtTxH8pop1"],
                              href: "https://api.spotify.com/v1/albums/6TJmQnO44YE5BtTxH8pop1",
                              id: "6TJmQnO44YE5BtTxH8pop1",
                              images: [albumImg1, albumImg2, albumImg3],
                              name: "Hot Fuss",
                              releaseDate: "2004-06-15",
                              releaseDatePrecision: "day",
                              restrictions: nil,
                              type: "album",
                              uri: "spotify:album:6TJmQnO44YE5BtTxH8pop1")

        let track = TrackJSON(album: album,
                              artists: [artist],
                              availableMarkets: [],
                              discNumber: 1,
                              durationMs: 222075,
                              explicit: false,
                              externalIds: ["isrc": "USIR20400274"],
                              externalUrls: ["spotify": "https://open.spotify.com/track/0eGsygTp906u18L0Oimnem"],
                              href: "https://api.spotify.com/v1/tracks/0eGsygTp906u18L0Oimnem",
                              id: "0eGsygTp906u18L0Oimnem",
                              isPlayable: nil,
                              linkedFrom: nil,
                              restrictions: nil,
                              name: "Mr. Brightside",
                              previewUrl: nil,
                              trackNumber: 2,
                              type: "track",
                              uri: "spotify:track:0eGsygTp906u18L0Oimnem",
                              isLocal: false)

        let expectation = CurrentlyPlayingJSON(context: context,
                                               timestamp: 1603635210819,
                                               progressMs: 16244,
                                               isPlaying: true,
                                               item: track,
                                               currentlyPlayingType: "track")

        let currentlyPlaying = elements.first!!

        XCTAssertEqual(currentlyPlaying.context, expectation.context)
        XCTAssertEqual(currentlyPlaying.item?.artists, expectation.item?.artists)
        XCTAssertEqual(currentlyPlaying.item?.album?.artists, expectation.item?.album?.artists)
        XCTAssertEqual(currentlyPlaying.item?.album, expectation.item?.album)
        XCTAssertEqual(currentlyPlaying.item, expectation.item)
        XCTAssertEqual(elements, [expectation])
    }

    var currentlyPlayingSample =
        """
        {
          "timestamp": 1603635210819,
          "context": {
            "external_urls": {
              "spotify": "https://open.spotify.com/playlist/7oorBA7hnNJngmox1JNrGW"
            },
            "href": "https://api.spotify.com/v1/playlists/7oorBA7hnNJngmox1JNrGW",
            "type": "playlist",
            "uri": "spotify:user:carlosefonseca:playlist:7oorBA7hnNJngmox1JNrGW"
          },
          "progress_ms": 16244,
          "item": {
            "album": {
              "album_type": "album",
              "artists": [
                {
                  "external_urls": {
                    "spotify": "https://open.spotify.com/artist/0C0XlULifJtAgn6ZNCW2eu"
                  },
                  "href": "https://api.spotify.com/v1/artists/0C0XlULifJtAgn6ZNCW2eu",
                  "id": "0C0XlULifJtAgn6ZNCW2eu",
                  "name": "The Killers",
                  "type": "artist",
                  "uri": "spotify:artist:0C0XlULifJtAgn6ZNCW2eu"
                }
              ],
              "available_markets": [],
              "external_urls": {
                "spotify": "https://open.spotify.com/album/6TJmQnO44YE5BtTxH8pop1"
              },
              "href": "https://api.spotify.com/v1/albums/6TJmQnO44YE5BtTxH8pop1",
              "id": "6TJmQnO44YE5BtTxH8pop1",
              "images": [
                {
                  "height": 640,
                  "url": "https://i.scdn.co/image/ab67616d0000b273797febe9f06dd027b67a3e64",
                  "width": 640
                },
                {
                  "height": 300,
                  "url": "https://i.scdn.co/image/ab67616d00001e02797febe9f06dd027b67a3e64",
                  "width": 300
                },
                {
                  "height": 64,
                  "url": "https://i.scdn.co/image/ab67616d00004851797febe9f06dd027b67a3e64",
                  "width": 64
                }
              ],
              "name": "Hot Fuss",
              "release_date": "2004-06-15",
              "release_date_precision": "day",
              "total_tracks": 12,
              "type": "album",
              "uri": "spotify:album:6TJmQnO44YE5BtTxH8pop1"
            },
            "artists": [
              {
                "external_urls": {
                  "spotify": "https://open.spotify.com/artist/0C0XlULifJtAgn6ZNCW2eu"
                },
                "href": "https://api.spotify.com/v1/artists/0C0XlULifJtAgn6ZNCW2eu",
                "id": "0C0XlULifJtAgn6ZNCW2eu",
                "name": "The Killers",
                "type": "artist",
                "uri": "spotify:artist:0C0XlULifJtAgn6ZNCW2eu"
              }
            ],
            "available_markets": [],
            "disc_number": 1,
            "duration_ms": 222075,
            "explicit": false,
            "external_ids": {
              "isrc": "USIR20400274"
            },
            "external_urls": {
              "spotify": "https://open.spotify.com/track/0eGsygTp906u18L0Oimnem"
            },
            "href": "https://api.spotify.com/v1/tracks/0eGsygTp906u18L0Oimnem",
            "id": "0eGsygTp906u18L0Oimnem",
            "is_local": false,
            "name": "Mr. Brightside",
            "popularity": 0,
            "preview_url": null,
            "track_number": 2,
            "type": "track",
            "uri": "spotify:track:0eGsygTp906u18L0Oimnem"
          },
          "currently_playing_type": "track",
          "actions": {
            "disallows": {
              "resuming": true
            }
          },
          "is_playing": true
        }
        """
}

public class FakeRequestManager: RequestManager {

    public var responses = [Result<Data, Error>]()

    public func execute(request: URLRequestable) -> AnyPublisher<Data, Error> {
        execute(urlRequest: request.urlRequest)
    }

    public func execute(urlRequest: URLRequest) -> AnyPublisher<Data, Error> {
        return Deferred {
            Future<Data, Error> { promise in
                guard self.responses.isEmpty == false else {
                    promise(.failure("NO QUEUED RESPOSE"))
                    return
                }

                let response = self.responses.removeFirst()

                switch response {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
