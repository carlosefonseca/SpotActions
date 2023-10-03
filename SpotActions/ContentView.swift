//
//  ContentView.swift
//

import CEFSpotifyCore
import Combine
import Intents
import SDWebImageSwiftUI
import SwiftUI
import CEFSpotifyDoubles

struct ContentView: View {

    @ObservedObject var presenter: MainPresenter

    fileprivate func userRow(_ name: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Button("Logout", action: { presenter.auth.logout() })
        }.padding()
    }

    fileprivate func mediaControls() -> some View {
        HStack {
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

            Menu {
                ForEach(self.presenter.devices) { _ in

                    Button {
                        // do something
                    } label: {
                        Text("Linear")
                        Image(systemName: "arrow.down.right.circle")
                    }
                }
            } label: {
                Text("Style")
                Image(systemName: "tag.circle")
            }

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

#Preview {
    ContentView(presenter: MainPresenter(auth: FakeSpotifyAuthManager(initialState: .loggedIn(token: TokenResponse())),
                                         userManager: FakeUserManager(defaultUser: true),
                                         playlistManager: FakePlaylistsManager(),
                                         playerManager: FakePlayerManager(),
                                         systemPublishers: iOSSystemPublishers()))
    
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
