//
//  SpotActionsApp.swift
//

import SwiftUI
import Intents
import CEFSpotifyCore
import Combine

@main
struct SpotActionsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var bag = Set<AnyCancellable>()

    var dependencies: Dependencies { appDelegate.dependencies }

    init() {
        dependencies.systemPublishers.appIsInForeground.sink { value in
            print("AppForeground: \(value)")
        }.store(in: &bag)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(presenter: MainPresenter(auth: dependencies.auth,
                                                 userManager: dependencies.userManager,
                                                 playlistManager: dependencies.playlistsManager,
                                                 playerManager: dependencies.playerManager,
                                                 systemPublishers: dependencies.systemPublishers))
        }
    }
}

// @UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var dependencies = iOSDependencies()

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
