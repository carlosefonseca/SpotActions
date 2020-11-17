//
// MainPresenter.swift
//

import SwiftUI
import AuthenticationServices
import CEFSpotifyCore
import Combine
// import CEFSpotifyDoubles
import SDWebImageSwiftUI

class MainPresenter: ObservableObject {

    var auth: SpotifyAuthManager

    @Published var isAuthenticated = false

    var userManager: UserManager

    @Published var user: UserJSON?

    var bag = Set<AnyCancellable>()

    @Published var error: String?

    var playlistManager: PlaylistsManager

    @Published var playlists: [PlaylistJSON] = []

    var playerManager: PlayerManager

    @Published var playing: CurrentlyPlayingJSON?

    @Published var devices: [DeviceJSON] = []

    var systemPublishers: SystemPublishers

    @Published var triggerUpdate: Int = 0

    var connect: iOSConnectivity

    public init(auth: SpotifyAuthManager, userManager: UserManager, playlistManager: PlaylistsManager, playerManager: PlayerManager, systemPublishers: SystemPublishers) {
        self.auth = auth
        self.userManager = userManager
        self.playlistManager = playlistManager
        self.playerManager = playerManager
        self.systemPublishers = systemPublishers

        connect = iOSConnectivity(authManager: auth)

        self.auth.statePublisher
            .receive(on: RunLoop.main)
            .sink { [self] authState in
                switch authState {
                case .notLoggedIn:
                    isAuthenticated = false
                case .loggedIn:
                    isAuthenticated = true
                case .error(let error):
                    isAuthenticated = false
                    self.error = error
                }
            }.store(in: &bag)

        self.userManager.userPublisher.print("Presenter>userManager.userPublisher")
            .handleEvents(receiveOutput: { _ in
                self.subscribeOthers()
            })
            .receive(on: RunLoop.main)
            .sink { self.user = $0 }
            .store(in: &bag)
    }

    func updateDevices() {
        playerManager.devices()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { self.devices = $0 })
            .store(in: &bag)
    }

    func subscribeOthers() {
        playlistManager.getFirstPageUserPlaylists()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { self.playlists = $0 })
            .store(in: &bag)

        updateDevices()

        systemPublishers.appIsInForeground
            .map { fg -> AnyPublisher<Int, Never> in
                if fg {
                    return Timer.publish(every: 100, on: .main, in: .common)
                        .autoconnect()
                        .print("TIMER-A")
                        .map { _ in 0 }
                        .prepend(0)
                        .eraseToAnyPublisher()
                } else {
                    return Empty(completeImmediately: false)
                        .replaceEmpty(with: 0)
                        .setFailureType(to: Never.self)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .sink(receiveCompletion: { _ in }) { self.triggerUpdate = $0 }
            .store(in: &bag)

        $triggerUpdate
            .eraseToAnyPublisher()
            .flatMap { _ -> AnyPublisher<Int, Error> in

                let a: AnyPublisher<Int, Error> = self.playerManager.getCurrentlyPlaying()
                    .receive(on: RunLoop.main)
                    .handleEvents(receiveOutput: { self.playing = $0 }).map { _ in 0 }
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()

                let b = self.playerManager.devices()
                    .receive(on: RunLoop.main)
                    .handleEvents(receiveOutput: { self.devices = $0 }).map { _ in 0 }
                    .eraseToAnyPublisher()

                return Publishers.Merge(a, b).eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in }) { _ in self.connect.sendWatchMessage(data: self.playing) }
            .store(in: &bag)
    }

    func refresh() {
        triggerUpdate = 0
    }

    func previous() {
        playerManager.previous()
            .receive(on: RunLoop.main)
            .handleEvents(receiveCompletion: { _ in self.triggerUpdate = 0 })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &bag)
    }

    func next() {
        playerManager.next()
            .receive(on: RunLoop.main)
            .handleEvents(receiveCompletion: { _ in self.triggerUpdate = 0 })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &bag)
    }

    func playPause() {
        let isPlaying = playing?.isPlaying == true
        let publisher: AnyPublisher<Data, Error>
        if isPlaying {
            publisher = playerManager.pause()
        } else {
            publisher = playerManager.play(contextUri: nil, deviceId: nil)
        }
        publisher
            .flatMap { _ -> AnyPublisher<Date, Never> in
                return Timer.publish(every: 0.5, on: .main, in: .common)
                    .autoconnect()
                    .eraseToAnyPublisher()
            }
            .flatMap { _ -> AnyPublisher<CurrentlyPlayingJSON?, Error> in
                return self.playerManager.getCurrentlyPlaying()
                    .mapError { e in e as Error }
                    .eraseToAnyPublisher()
            }
            .drop(while: { (playing) -> Bool in
                return playing?.isPlaying == isPlaying
            })
            .first()
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { playing in
                self.playing = playing
                self.connect.sendWatchMessage(data: playing)
            })
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &bag)
    }

    func play(playlist: PlaylistJSON) {
        playerManager.play(contextUri: playlist.uri, deviceId: nil)
            .receive(on: RunLoop.main)
            .handleEvents(receiveCompletion: { _ in self.triggerUpdate = 0 })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &bag)
    }

    func transferPlayback(to device: DeviceJSON) {
        guard !device.isActive else { return }
        playerManager.transferPlayback(to: device.id)
            .receive(on: RunLoop.main)
            .handleEvents(receiveCompletion: { _ in self.triggerUpdate = 0 })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &bag)
    }
}
