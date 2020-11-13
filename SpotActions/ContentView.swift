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

    @Published var playlists: [PlaylistJSON]?

    var playerManager: PlayerManager

    @Published var playing: CurrentlyPlayingJSON?

    public init(auth: SpotifyAuthManager, userManager: UserManager, playlistManager: PlaylistsManager, playerManager: PlayerManager) {
        self.auth = auth
        self.userManager = userManager
        self.playlistManager = playlistManager
        self.playerManager = playerManager

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
            .receive(on: RunLoop.main)
            .sink { self.user = $0 }
            .store(in: &bag)

        self.playlistManager.publisher
            .receive(on: RunLoop.main)
            .sink { self.playlists = $0 }
            .store(in: &bag)

        self.playerManager.getCurrentlyPlaying()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in }) { self.playing = $0 }
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
            Button(action: { presenter.playerManager.previous() }) {
                Image(systemName: "backward.end.fill")
                    .foregroundColor(.primary)
            }.padding()

            Button(action: {}) {
                Image(systemName: "play.circle")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(.primary)
            }.padding()

            Button(action: {}) {
                Image(systemName: "forward.end.fill")
                    .foregroundColor(.primary)
            }.padding()
        }
    }

    @ViewBuilder
    var body: some View {
        VStack {
            if presenter.isAuthenticated {
                if let user = presenter.user, let displayName = user.displayName {
                    Spacer()
                    Divider()

                    if let playing = presenter.playing, let item = playing.item {
                        Text(playing.isPlaying ? "Playing" : "Not playing")
                        HStack(alignment: .bottom) {

                            WebImage(url: item.albumArtUrl)
                                .resizable()
                                .placeholder { Image(systemName: "music.mic").font(.system(size: 36, weight: .thin)) }
                                .scaledToFill()
                                .frame(width: 150.0, height: 150.0)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10.0)
                                .padding()

                            VStack(alignment: .center) {

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
                                         playerManager: FakePlayerManager()))
    }
}
