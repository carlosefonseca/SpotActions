//
// iOSDependencies.swift
//

import SwiftUI
import Intents
import CEFSpotifyCore
import Combine

struct iOSDependencies: Dependencies {
    var keychain: CredentialStore

    var auth: SpotifyAuthManager

    var spotifyRequestManager: RequestManager

    var requester: URLRequester

    var gateways: Gateways

    var userManager: UserManager

    var playlistsManager: PlaylistsManager

    var playerManager: PlayerManager

    var trackFilterService: TrackFilterService

    var trackMixerService: TrackMixerService

    var systemPublishers: SystemPublishers

    init() {
        keychain = Keychain()
        requester = UrlSessionRequester()
        auth = SpotifyAuthManagerImplementation(webAuthManager: WebAuthManager(), credentialStore: keychain, requester: requester)
        spotifyRequestManager = AuthenticatedSpotifyRequestManager(auth: auth, requester: requester)
        gateways = Gateways(baseURL: URL(string: "https://api.spotify.com")!, requestManager: spotifyRequestManager)

        userManager = UserManagerImplementation(auth: auth, gateway: gateways.userProfile)
        playlistsManager = PlaylistsManagerImplementation(auth: auth, gateway: gateways.playlists)
        playerManager = PlayerManagerImplementation(gateway: gateways.player)

        trackFilterService = TrackFilterServiceImplementation(playlistsManager: playlistsManager)
        trackMixerService = TrackMixerServiceImplementation(playlistsManager: playlistsManager)

        systemPublishers = iOSSystemPublishers()
    }
}
