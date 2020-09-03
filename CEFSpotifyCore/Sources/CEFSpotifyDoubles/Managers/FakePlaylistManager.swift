//
//  FakePlaylistsManager.swift
//

import Foundation
import Combine
import CEFSpotifyCore

public class FakePlaylistsManager: PlaylistsManager {

    public init() {}

    public func getUserPlaylistsEach() -> Future<PagedPlaylistsJSON, SpotifyRequestError> {
        return Future { _ in }
    }
}
