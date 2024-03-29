//
// PlaylistsManagerTests.swift
//

import Foundation
import Combine
import XCTest
@testable import CEFSpotifyCore
import CEFSpotifyDoubles
import CombineExpectations

struct TestError: Error, Equatable {}

class PlaylistsManagerTests: XCTestCase {
    var bag = Set<AnyCancellable>()

    var fakeAuth: FakeSpotifyAuthManager!
    var fakeGateway: FakeSpotifyPlaylistsGateway!
    var playlistsManager: PlaylistsManager!

    let artist1 = ArtistJSON(externalUrls: nil, href: nil, id: "artist1", name: "Artist 1", type: nil, uri: "spotify:artist:0gxyHStUsqpMadRV0Di1Qt")
    let artist2 = ArtistJSON(externalUrls: nil, href: nil, id: "artist2", name: "Artist 2", type: nil, uri: "spotify:artist:2jzc5TC5TVFLXQlBNiIUzE")
    let artist3 = ArtistJSON(externalUrls: nil, href: nil, id: "artist3", name: "Artist 3", type: nil, uri: "spotify:artist:7Bah8E0kCETqEpAHI6CPzQ")
    let artist4 = ArtistJSON(externalUrls: nil, href: nil, id: "artist4", name: "Artist 4", type: nil, uri: "spotify:artist:0grdhNhiRLFBaFVyybqsj6")

    lazy var track1 = { TrackJSON(artists: [artist1], availableMarkets: nil, discNumber: nil, durationMs: nil, explicit: nil, externalUrls: nil, href: nil, id: "track1", isPlayable: nil, name: "Track 1", previewUrl: nil, trackNumber: nil, type: nil, uri: nil, isLocal: nil) }()
    lazy var track2 = { TrackJSON(artists: [artist2], availableMarkets: nil, discNumber: nil, durationMs: nil, explicit: nil, externalUrls: nil, href: nil, id: "track2", isPlayable: nil, name: "Track 2", previewUrl: nil, trackNumber: nil, type: nil, uri: nil, isLocal: nil) }()
    lazy var track3 = { TrackJSON(artists: [artist3], availableMarkets: nil, discNumber: nil, durationMs: nil, explicit: nil, externalUrls: nil, href: nil, id: "track3", isPlayable: nil, name: "Track 3", previewUrl: nil, trackNumber: nil, type: nil, uri: nil, isLocal: nil) }()
    lazy var track4 = { TrackJSON(artists: [artist4], availableMarkets: nil, discNumber: nil, durationMs: nil, explicit: nil, externalUrls: nil, href: nil, id: "track4", isPlayable: nil, name: "Track 4", previewUrl: nil, trackNumber: nil, type: nil, uri: nil, isLocal: nil) }()

    lazy var pageTrack1 = { PageTrackJSON(addedAt: nil, addedBy: nil, isLocal: nil, track: track1) }()
    lazy var pageTrack2 = { PageTrackJSON(addedAt: nil, addedBy: nil, isLocal: nil, track: track2) }()
    lazy var pageTrack3 = { PageTrackJSON(addedAt: nil, addedBy: nil, isLocal: nil, track: track3) }()
    lazy var pageTrack4 = { PageTrackJSON(addedAt: nil, addedBy: nil, isLocal: nil, track: track4) }()

    let playlist1 = PlaylistJSON(id: "playlist1")
    let playlist2 = PlaylistJSON(id: "playlist2")
    let playlist3 = PlaylistJSON(id: "playlist3")
    let playlist4 = PlaylistJSON(id: "playlist4")

    lazy var pagePlaylistsAll = { PagedPlaylistsJSON(items: [playlist1, playlist2, playlist3, playlist4], next: nil, offset: 0, total: 4) }()
    lazy var pagePlaylists1 = { PagedPlaylistsJSON(items: [playlist1, playlist2], next: "nextPlaylists", offset: 0, total: 4) }()
    lazy var pagePlaylists2 = { PagedPlaylistsJSON(items: [playlist3, playlist4], next: nil, offset: 2, total: 4) }()

    override func setUp() {
        bag.removeAll()

        fakeAuth = FakeSpotifyAuthManager(initialState: .loggedIn(token: TokenResponse()))

        fakeGateway = FakeSpotifyPlaylistsGateway()

        playlistsManager = PlaylistsManagerImplementation(auth: fakeAuth,
                                                          gateway: fakeGateway,
                                                          maxTracksToSaveAtOnce: 2)
    }

    func test_fetch_single_page_of_user_playlists() {
        fakeGateway.userPlaylistsResponses.append(Result.success(pagePlaylistsAll))

        let finishedExpectation = expectation(description: "finished")
        var output: [PlaylistJSON]?

        playlistsManager.getAllUserPlaylists()
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

        XCTAssertEqual(output, [playlist1, playlist2, playlist3, playlist4])

        let expectedCalls: [FakeSpotifyPlaylistsGateway.Methods] = [
            .getUserPlaylists(limit: 50, offset: 0),
        ]

        XCTAssertEqual(fakeGateway.calls, expectedCalls)
    }

    func test_fetch_multiple_page_of_user_playlists() {
        fakeGateway.userPlaylistsResponses.append(Result.success(pagePlaylists1))
        fakeGateway.nextUserPlaylistsResponses.append(Result.success(pagePlaylists2))

        let finishedExpectation = expectation(description: "finished")
        var output: [PlaylistJSON]?

        playlistsManager.getAllUserPlaylists()
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

        XCTAssertEqual(output, [playlist1, playlist2, playlist3, playlist4])

        let expectedCalls: [FakeSpotifyPlaylistsGateway.Methods] = [
            .getUserPlaylists(limit: 50, offset: 0),
            .getNextUserPlaylists(next: URL(string: "nextPlaylists")!),
        ]

        XCTAssertEqual(fakeGateway.calls, expectedCalls)
    }

    func test_fetch_single_page_of_tracks() {
        let singlePage = PagedTracksJSON(href: nil, items: [pageTrack1, pageTrack2, pageTrack3, pageTrack4], limit: 4, next: nil, offset: 0, previous: nil, total: 4)

        fakeGateway.playlistTracksResponses.append(Result.success(singlePage))

        let finishedExpectation = expectation(description: "finished")
        var output: [TrackJSON]?

        playlistsManager.getAllPlaylistTracks(playlistId: "playlist1")
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

        XCTAssertEqual(output, [track1, track2, track3, track4])

        let expectedCalls: [FakeSpotifyPlaylistsGateway.Methods] = [
            .getPlaylistTracks(playlistId: "playlist1", offset: 0),
        ]

        XCTAssertEqual(fakeGateway.calls, expectedCalls)
    }

    func test_fetch_multiple_pages_of_tracks() {
        let page1 = PagedTracksJSON(href: nil, items: [pageTrack1], limit: 1, next: "offset1", offset: 0, previous: nil, total: 4)
        let page2 = PagedTracksJSON(href: nil, items: [pageTrack2], limit: 1, next: "offset2", offset: 1, previous: nil, total: 4)
        let page3 = PagedTracksJSON(href: nil, items: [pageTrack3], limit: 1, next: "offset3", offset: 2, previous: nil, total: 4)
        let page4 = PagedTracksJSON(href: nil, items: [pageTrack4], limit: 1, next: nil, offset: 3, previous: nil, total: 4)

        fakeGateway.playlistTracksResponses.append(Result.success(page1))
        fakeGateway.nextPlaylistTracksResponses = [Result.success(page2), Result.success(page3), Result.success(page4)]

        let finishedExpectation = expectation(description: "finished")
        var output: [TrackJSON]?

        playlistsManager.getAllPlaylistTracks(playlistId: "playlist1")
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

        XCTAssertEqual(output, [track1, track2, track3, track4])

        let expectedCalls: [FakeSpotifyPlaylistsGateway.Methods] = [
            .getPlaylistTracks(playlistId: "playlist1", offset: 0),
            .getNextPlaylistTracks(next: URL(string: "offset1")),
            .getNextPlaylistTracks(next: URL(string: "offset2")),
            .getNextPlaylistTracks(next: URL(string: "offset3")),
        ]

        XCTAssertEqual(fakeGateway.calls, expectedCalls)
    }

    func test_fetch_single_page_of_tracks_fails() {
        fakeGateway.playlistTracksResponses.append(Result.failure(TestError()))

        let finishedExpectation = expectation(description: "finished")
        var output: PlaylistsManagerError?

        playlistsManager.getAllPlaylistTracks(playlistId: "playlist1")
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .failure(let error) = completion else {
                    XCTFail()
                    return
                }
                output = error
            } receiveValue: { _ in
                XCTFail()
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        switch output {
        case .requestError(let error):
            XCTAssertEqual(error as? TestError, TestError())
        default:
            XCTFail()
        }

        let expectedCalls: [FakeSpotifyPlaylistsGateway.Methods] = [
            .getPlaylistTracks(playlistId: "playlist1", offset: 0),
        ]

        XCTAssertEqual(fakeGateway.calls, expectedCalls)
    }

    func test_single_page_save() {
        fakeGateway.replaceResponses.append(nil)

        let finishedExpectation = expectation(description: "finished")

        try! playlistsManager.save(tracks: [track1, track2], on: playlist1)
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { _ in
                XCTFail()
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        let expectedCalls: [FakeSpotifyPlaylistsGateway.Methods] = [
            .replace(tracks: ["track1", "track2"], playlistId: "playlist1"),
        ]
        XCTAssertEqual(fakeGateway.calls, expectedCalls)
    }

    func test_multi_page_save() {
        fakeGateway.replaceResponses.append(nil)
        fakeGateway.addResponses.append(nil)

        let finishedExpectation = expectation(description: "finished")

        try! playlistsManager.save(tracks: [track1, track2, track3, track4], on: playlist1)
            .sink { completion in
                finishedExpectation.fulfill()
                guard case .finished = completion else {
                    XCTFail()
                    return
                }
            } receiveValue: { _ in
                XCTFail()
            }.store(in: &bag)

        waitForExpectations(timeout: 1)

        let expectedCalls: [FakeSpotifyPlaylistsGateway.Methods] = [
            .replace(tracks: ["track1", "track2"], playlistId: "playlist1"),
            .add(tracks: ["track3", "track4"], playlistId: "playlist1", index: nil),
        ]
        XCTAssertEqual(fakeGateway.calls, expectedCalls)
    }

    func test_get_multiple_playlist_tracks() {
        let pIDs = ["p1", "p2", "p3", "p4"]

        let playlist1 = PagedTracksJSON(href: nil, items: [pageTrack1], limit: 1, next: nil, offset: 0, previous: nil, total: 1)
        let playlist2 = PagedTracksJSON(href: nil, items: [pageTrack2], limit: 1, next: nil, offset: 0, previous: nil, total: 1)
        let playlist3 = PagedTracksJSON(href: nil, items: [pageTrack3], limit: 1, next: nil, offset: 0, previous: nil, total: 1)
        let playlist4 = PagedTracksJSON(href: nil, items: [pageTrack4], limit: 1, next: nil, offset: 0, previous: nil, total: 1)

        fakeGateway.playlistTracksResponses.append(contentsOf: [
            .success(playlist1), .success(playlist2), .success(playlist3), .success(playlist4),
        ])

        let publisher = playlistsManager.getMultiplePlaylistTracks(playlistIds: pIDs)

        let elements = try? wait(for: publisher.record().elements, timeout: 1)

        XCTAssertEqual(elements, [[track1], [track2], [track3], [track4]])
    }

    func test_blah() {
        _ =
            """
            {
              "href" : "https://api.spotify.com/v1/playlists/2llsWuBdZxeBxumSun0scv/tracks?offset=0&limit=100",
              "items" : [ {
                "added_at" : "2020-03-20T09:22:03Z",
                "added_by" : {
                  "external_urls" : {
                    "spotify" : "https://open.spotify.com/user/carlosefonseca"
                  },
                  "href" : "https://api.spotify.com/v1/users/carlosefonseca",
                  "id" : "carlosefonseca",
                  "type" : "user",
                  "uri" : "spotify:user:carlosefonseca"
                },
                "is_local" : false,
                "primary_color" : null,
                "track" : {
                  "album" : {
                    "album_type" : "album",
                    "artists" : [ {
                      "external_urls" : {
                        "spotify" : "https://open.spotify.com/artist/7qAcXJgt1PWnxwUgxMdyuk"
                      },
                      "href" : "https://api.spotify.com/v1/artists/7qAcXJgt1PWnxwUgxMdyuk",
                      "id" : "7qAcXJgt1PWnxwUgxMdyuk",
                      "name" : "Sick Puppies",
                      "type" : "artist",
                      "uri" : "spotify:artist:7qAcXJgt1PWnxwUgxMdyuk"
                    } ],
                    "available_markets" : [ "AD", "AE", "AL", "AR", "AT", "BA", "BE", "BG", "BH", "BO", "BR", "BY", "CH", "CL", "CO", "CR", "CY", "CZ", "DE", "DK", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FR", "GR", "GT", "HK", "HN", "HR", "HU", "ID", "IL", "IN", "IS", "IT", "JO", "KW", "KZ", "LB", "LI", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MK", "MT", "MX", "MY", "NI", "NL", "NO", "OM", "PA", "PE", "PH", "PL", "PS", "PT", "PY", "QA", "RO", "RS", "RU", "SA", "SE", "SG", "SI", "SK", "SV", "TH", "TN", "TR", "TW", "UA", "UY", "VN", "XK", "ZA" ],
                    "external_urls" : {
                      "spotify" : "https://open.spotify.com/album/1lzHraZnbTovp0SL4aZD4R"
                    },
                    "href" : "https://api.spotify.com/v1/albums/1lzHraZnbTovp0SL4aZD4R",
                    "id" : "1lzHraZnbTovp0SL4aZD4R",
                    "images" : [ {
                      "height" : 640,
                      "url" : "https://i.scdn.co/image/ab67616d0000b2730bccc1eafb39ec9629368df6",
                      "width" : 640
                    }, {
                      "height" : 300,
                      "url" : "https://i.scdn.co/image/ab67616d00001e020bccc1eafb39ec9629368df6",
                      "width" : 300
                    }, {
                      "height" : 64,
                      "url" : "https://i.scdn.co/image/ab67616d000048510bccc1eafb39ec9629368df6",
                      "width" : 64
                    } ],
                    "name" : "Tri-Polar (International Version)",
                    "release_date" : "2009",
                    "release_date_precision" : "year",
                    "total_tracks" : 12,
                    "type" : "album",
                    "uri" : "spotify:album:1lzHraZnbTovp0SL4aZD4R"
                  },
                  "artists" : [ {
                    "external_urls" : {
                      "spotify" : "https://open.spotify.com/artist/7qAcXJgt1PWnxwUgxMdyuk"
                    },
                    "href" : "https://api.spotify.com/v1/artists/7qAcXJgt1PWnxwUgxMdyuk",
                    "id" : "7qAcXJgt1PWnxwUgxMdyuk",
                    "name" : "Sick Puppies",
                    "type" : "artist",
                    "uri" : "spotify:artist:7qAcXJgt1PWnxwUgxMdyuk"
                  } ],
                  "available_markets" : [ "AD", "AE", "AL", "AR", "AT", "BA", "BE", "BG", "BH", "BO", "BR", "BY", "CH", "CL", "CO", "CR", "CY", "CZ", "DE", "DK", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FR", "GR", "GT", "HK", "HN", "HR", "HU", "ID", "IL", "IN", "IS", "IT", "JO", "KW", "KZ", "LB", "LI", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MK", "MT", "MX", "MY", "NI", "NL", "NO", "OM", "PA", "PE", "PH", "PL", "PS", "PT", "PY", "QA", "RO", "RS", "RU", "SA", "SE", "SG", "SI", "SK", "SV", "TH", "TN", "TR", "TW", "UA", "UY", "VN", "XK", "ZA" ],
                  "disc_number" : 1,
                  "duration_ms" : 187346,
                  "episode" : false,
                  "explicit" : true,
                  "external_ids" : {
                    "isrc" : "USVI20900226"
                  },
                  "external_urls" : {
                    "spotify" : "https://open.spotify.com/track/5FQXMRDSTkn9fowDJ3kZo8"
                  },
                  "href" : "https://api.spotify.com/v1/tracks/5FQXMRDSTkn9fowDJ3kZo8",
                  "id" : "5FQXMRDSTkn9fowDJ3kZo8",
                  "is_local" : false,
                  "name" : "You're Going Down",
                  "popularity" : 64,
                  "preview_url" : "https://p.scdn.co/mp3-preview/674a8cfd8e2612796973006f0dd9cbe8a741472e?cid=67193a3350af4e0e9b2fafd6c59c7934",
                  "track" : true,
                  "track_number" : 5,
                  "type" : "track",
                  "uri" : "spotify:track:5FQXMRDSTkn9fowDJ3kZo8"
                },
                "video_thumbnail" : {
                  "url" : null
                }
              }, {
                "added_at" : "2020-03-20T09:22:03Z",
                "added_by" : {
                  "external_urls" : {
                    "spotify" : "https://open.spotify.com/user/carlosefonseca"
                  },
                  "href" : "https://api.spotify.com/v1/users/carlosefonseca",
                  "id" : "carlosefonseca",
                  "type" : "user",
                  "uri" : "spotify:user:carlosefonseca"
                },
                "is_local" : false,
                "primary_color" : null,
                "track" : {
                  "album" : {
                    "album_type" : "album",
                    "artists" : [ {
                      "external_urls" : {
                        "spotify" : "https://open.spotify.com/artist/7qAcXJgt1PWnxwUgxMdyuk"
                      },
                      "href" : "https://api.spotify.com/v1/artists/7qAcXJgt1PWnxwUgxMdyuk",
                      "id" : "7qAcXJgt1PWnxwUgxMdyuk",
                      "name" : "Sick Puppies",
                      "type" : "artist",
                      "uri" : "spotify:artist:7qAcXJgt1PWnxwUgxMdyuk"
                    } ],
                    "available_markets" : [ "AD", "AL", "AR", "AT", "BA", "BE", "BG", "BO", "BR", "BY", "CA", "CH", "CL", "CO", "CR", "CY", "CZ", "DE", "DK", "DO", "EC", "EE", "ES", "FI", "FR", "GB", "GR", "GT", "HK", "HN", "HR", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JP", "KZ", "LI", "LT", "LU", "LV", "MC", "MD", "ME", "MK", "MT", "MX", "MY", "NI", "NL", "NO", "PA", "PE", "PH", "PL", "PS", "PT", "PY", "RO", "RS", "RU", "SE", "SG", "SI", "SK", "SV", "TH", "TR", "TW", "UA", "US", "UY", "VN", "XK", "ZA" ],
                    "external_urls" : {
                      "spotify" : "https://open.spotify.com/album/6rL7tAqRqT4DL4I1bcADTi"
                    },
                    "href" : "https://api.spotify.com/v1/albums/6rL7tAqRqT4DL4I1bcADTi",
                    "id" : "6rL7tAqRqT4DL4I1bcADTi",
                    "images" : [ {
                      "height" : 640,
                      "url" : "https://i.scdn.co/image/ab67616d0000b273f758e1bf25ac7479825e4c9c",
                      "width" : 640
                    }, {
                      "height" : 300,
                      "url" : "https://i.scdn.co/image/ab67616d00001e02f758e1bf25ac7479825e4c9c",
                      "width" : 300
                    }, {
                      "height" : 64,
                      "url" : "https://i.scdn.co/image/ab67616d00004851f758e1bf25ac7479825e4c9c",
                      "width" : 64
                    } ],
                    "name" : "Connect",
                    "release_date" : "2013-01-01",
                    "release_date_precision" : "day",
                    "total_tracks" : 12,
                    "type" : "album",
                    "uri" : "spotify:album:6rL7tAqRqT4DL4I1bcADTi"
                  },
                  "artists" : [ {
                    "external_urls" : {
                      "spotify" : "https://open.spotify.com/artist/7qAcXJgt1PWnxwUgxMdyuk"
                    },
                    "href" : "https://api.spotify.com/v1/artists/7qAcXJgt1PWnxwUgxMdyuk",
                    "id" : "7qAcXJgt1PWnxwUgxMdyuk",
                    "name" : "Sick Puppies",
                    "type" : "artist",
                    "uri" : "spotify:artist:7qAcXJgt1PWnxwUgxMdyuk"
                  } ],
                  "available_markets" : [ "AD", "AL", "AR", "AT", "BA", "BE", "BG", "BO", "BR", "BY", "CA", "CH", "CL", "CO", "CR", "CY", "CZ", "DE", "DK", "DO", "EC", "EE", "ES", "FI", "FR", "GB", "GR", "GT", "HK", "HN", "HR", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JP", "KZ", "LI", "LT", "LU", "LV", "MC", "MD", "ME", "MK", "MT", "MX", "MY", "NI", "NL", "NO", "PA", "PE", "PH", "PL", "PS", "PT", "PY", "RO", "RS", "RU", "SE", "SG", "SI", "SK", "SV", "TH", "TR", "TW", "UA", "US", "UY", "VN", "XK", "ZA" ],
                  "disc_number" : 1,
                  "duration_ms" : 175720,
                  "episode" : false,
                  "explicit" : true,
                  "external_ids" : {
                    "isrc" : "USUM71305557"
                  },
                  "external_urls" : {
                    "spotify" : "https://open.spotify.com/track/0is4yL58CcQ4Gv4WgTGr9N"
                  },
                  "href" : "https://api.spotify.com/v1/tracks/0is4yL58CcQ4Gv4WgTGr9N",
                  "id" : "0is4yL58CcQ4Gv4WgTGr9N",
                  "is_local" : false,
                  "name" : "Gunfight",
                  "popularity" : 59,
                  "preview_url" : "https://p.scdn.co/mp3-preview/803137313f735090b3f8f083d8122c1a8bb75939?cid=67193a3350af4e0e9b2fafd6c59c7934",
                  "track" : true,
                  "track_number" : 4,
                  "type" : "track",
                  "uri" : "spotify:track:0is4yL58CcQ4Gv4WgTGr9N"
                },
                "video_thumbnail" : {
                  "url" : null
                }
              }],
              "limit" : 100,
              "next" : null,
              "offset" : 0,
              "previous" : null,
              "total" : 50
            }
            """
    }
}
