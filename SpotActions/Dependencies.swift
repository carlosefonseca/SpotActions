//
// Dependencies.swift
//

import SwiftUI
import Intents
import CEFSpotifyCore
import Combine

struct Gateways {
    let userProfile: SpotifyUserProfileGateway
    let playlists: SpotifyPlaylistsGateway
    let player: SpotifyPlayerGateway

    init(baseURL: URL, requestManager: RequestManager) {
        userProfile = SpotifyUserProfileGatewayImplementation(baseURL: baseURL, requestManager: requestManager)
        playlists = SpotifyPlaylistsGatewayImplementation(baseURL: baseURL, requestManager: requestManager)
        player = SpotifyPlayerGatewayImplementation(baseURL: baseURL, requestManager: requestManager)
    }
}

protocol Dependencies {
    var keychain: CredentialStore { get }
    var auth: SpotifyAuthManager { get }
    var spotifyRequestManager: RequestManager { get }
    var requester: URLRequester { get }

    var gateways: Gateways { get }

    var userManager: UserManager { get }
    var playlistsManager: PlaylistsManager { get }
    var playerManager: PlayerManager { get }

    var trackFilterService: TrackFilterService { get }
    var trackMixerService: TrackMixerService { get }

    var systemPublishers: SystemPublishers { get }
}

