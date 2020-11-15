//
//  ContentView.swift
//

import SwiftUI
import AuthenticationServices
import CEFSpotifyCore
import Combine
import CEFSpotifyDoubles
import SDWebImageSwiftUI

class Presenter: ObservableObject {

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

    public init(auth: SpotifyAuthManager, userManager: UserManager, playlistManager: PlaylistsManager, playerManager: PlayerManager, systemPublishers: SystemPublishers) {
        self.auth = auth
        self.userManager = userManager
        self.playlistManager = playlistManager
        self.playerManager = playerManager
        self.systemPublishers = systemPublishers

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
            .sink(receiveCompletion: { _ in }) { _ in }
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
            .handleEvents(receiveOutput: { playing in self.playing = playing })
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

struct ContentView: View {

    @ObservedObject var presenter: Presenter

    fileprivate func userRow(_ name: String) -> some View {
        return HStack {
            Text(name)
            Spacer()
            Button("Logout", action: { presenter.auth.logout() })
        }.padding()
    }

    fileprivate func mediaControls() -> some View {
        return HStack {
            Button(action: { presenter.previous() }) {
                Image(systemName: "backward.end.fill")
                    .foregroundColor(.primary)
            }.padding()

            Button(action: { presenter.playPause() }) {
                Image(systemName: presenter.playing?.isPlaying == true ? "pause.circle" : "play.circle")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(.primary)
            }.padding()

            Button(action: { presenter.next() }) {
                Image(systemName: "forward.end.fill")
                    .foregroundColor(.primary)
            }.padding()
        }
    }

    @ViewBuilder
    fileprivate func playlists() -> some View {

        if presenter.playlists.isEmpty {
            Spacer()
            ProgressView()
            Text("Loading playlists…")
            Spacer()
        } else {

            List {
                Section(header: Text("Playlists")) {
                    ForEach(self.presenter.playlists) { p in
                        Button(action: {
                            self.presenter.play(playlist: p)
                        }, label: {

                            HStack {
                                Label(p.name ?? "?", systemImage: "music.note.list")
                                if p.uri == self.presenter.playing?.context?.uri?.userless {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        })
                    }
                }
            }
        }
    }

    @ViewBuilder
    func devices() -> some View {
        if presenter.playlists.isEmpty {
            Spacer()
            ProgressView()
            Text("Loading devices…")
            Spacer()
        } else {

            HStack {
                Text("DEVICES")
                Spacer()
            }.background(Color("tablePlainHeaderFooterFloatingBackgroundColor"))

            ScrollView(.horizontal) {
                HStack {
                    ForEach(self.presenter.devices) { p in
                        Button(action: { self.presenter.transferPlayback(to: p) }) {
                            HStack {
                                Label(p.name, systemImage: p.icon())
                                if p.isActive {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Divider()
                    }
                }
            }.frame(height: 40)
        }
    }

    var body: some View {
        VStack {
            if presenter.isAuthenticated {
                if let user = presenter.user, let displayName = user.displayName {
                    playlists()
                    Divider()

                    devices()
                    Divider()

                    if let playing = presenter.playing, let item = playing.item {
                        HStack(alignment: .bottom) {

                            ZStack {
                                Image(systemName: "music.mic").font(.system(size: 36, weight: .thin))
                                WebImage(url: item.albumArtUrl)
                                    .resizable()
//                                .placeholder {  }
//                                    .transition(.fade(duration: 0.5))
                                    .transition(.fade)
                                    .scaledToFill()
                            }
                            .frame(width: 150.0, height: 150.0)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10.0)
                            .padding()

                            VStack(alignment: .center) {
                                HStack {
                                    Spacer()
                                    Button(action: { presenter.refresh() }, label: {
                                        Image(systemName: "arrow.clockwise.circle")
                                    })
                                }

//                                if let contextType = playing.context?.type {
//                                    Text("Playing \(contextType)!")
//                                        .font(.caption)
//                                        .padding(1.0)
//                                }

                                Text(item.name!)
                                    .font(.headline)
                                Text(item.artistNames.joined(separator: ", "))
                                    .font(.subheadline)

                                mediaControls()
                            }
                            Spacer()
                        }
                    } else {
                        Text("Nothing is playing")
                    }

                    Divider()

                    userRow(displayName)
                } else {
                    ProgressView()
                }
            } else {
                Button("Login", action: { presenter.auth.login() })
                if let error = presenter.error {
                    Text("Error: \(error)").foregroundColor(.red)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(presenter: Presenter(auth: FakeSpotifyAuthManager(),
                                         userManager: FakeUserManager(),
                                         playlistManager: FakePlaylistsManager(),
                                         playerManager: FakePlayerManager(),
                                         systemPublishers: SystemPublishersImplementation()))
    }
}

extension DeviceJSON {
    func icon() -> String {
        switch type {
        case "Computer":
            return "desktopcomputer"
        case "Smartphone":
            return "phone"
        case "Speaker":
            return "hifispeaker"
        default:
            return "questionmark.circle"
        }
    }
}
