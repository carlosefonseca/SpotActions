//
//  SpotActionsApp.swift
//

import SwiftUI
import Intents
import CEFSpotifyCore

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

struct Dependencies {
    var keychain: CredentialStore
    var auth: SpotifyAuthManager
    var spotifyRequestManager: RequestManager
    var requester: URLRequester

    var gateways: Gateways

    var userManager: UserManager
    var playlistsManager: PlaylistsManager
    var playerManager: PlayerManager

    var trackFilterService : TrackFilterService
    var trackMixerService : TrackMixerService

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
    }
}

@main
struct SpotActionsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var dependencies: Dependencies { appDelegate.dependencies }

    var body: some Scene {
        WindowGroup {
            ContentView(presenter: Presenter(auth: dependencies.auth,
                                             userManager: dependencies.userManager,
                                             playlistManager: dependencies.playlistsManager))
        }
    }
}

// @UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var dependencies = Dependencies()

    lazy var userProfileHandler: GetUserProfileHandler = { GetUserProfileHandler(auth: dependencies.auth, userManager: dependencies.userManager) }()
    lazy var userPlaylistHandler: GetUserPlaylistsHandler = { GetUserPlaylistsHandler(auth: dependencies.auth, userManager: dependencies.userManager, playlistsManager: dependencies.playlistsManager) }()
    lazy var playlistTracksHandler: GetPlaylistTracksHandler = { GetPlaylistTracksHandler(auth: dependencies.auth, playlistsManager: dependencies.playlistsManager, playerManager: dependencies.playerManager) }()
    lazy var saveTracksOnPlaylistHandler = { SaveTracksOnPlaylistHandler(auth: dependencies.auth, playlistsManager: dependencies.playlistsManager) }()

    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        switch intent {
        case is GetUserProfileIntent:
            return userProfileHandler
        case is GetUserPlaylistsIntent:
            return userPlaylistHandler
        case is GetPlaylistTracksIntent:
            return playlistTracksHandler
        case is SaveTracksOnPlaylistIntent:
            return saveTracksOnPlaylistHandler
        case is FilterTracksIntent:
            return FilterTracksHandler(playlistsManager: dependencies.playlistsManager, trackFilterService: dependencies.trackFilterService)
        case is GetPlayingTrackIntent:
            return GetPlayingTrackHandler(auth: dependencies.auth, playerManager: dependencies.playerManager)
        case is GetPlayingPlaylistIntent:
            return GetPlayingPlaylistHandler(auth: dependencies.auth, playerManager: dependencies.playerManager, playlistManager: dependencies.playlistsManager)
        case is MixTracksIntent:
            return MixTracksHandler(auth: dependencies.auth, playlistsManager: dependencies.playlistsManager, trackMixerService: dependencies.trackMixerService)
        case is GetDetailsOfTrackIntent:
            return GetDetailsOfTrackHandler()
        case is RemoveTracksFromPlaylistsIntent:
            return RemoveTracksFromPlaylistsHandler(auth: dependencies.auth, playlistsManager: dependencies.playlistsManager)
        default:
            fatalError("No handler for this intent")
        }
    }
}
