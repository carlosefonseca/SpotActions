//
// SpotActionsApp.swift
//

import SwiftUI
import CEFSpotifyCore
import Combine

@main
struct SpotActionsApp: App {
    var bag = Set<AnyCancellable>()

    var dependencies = WatchDependencies()

    var systemPublishers: SystemPublishers = WatchSystemPublishers()

    var connect : WatchConnect

    init() {
        systemPublishers.appIsInForeground.sink { value in
            print("AppForeground: \(value)")
        }.store(in: &bag)

        connect = WatchConnect()
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
