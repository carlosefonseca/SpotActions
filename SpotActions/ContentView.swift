//
//  ContentView.swift
//

import SwiftUI
import Intents
import CEFSpotifyCore
import Combine
import SDWebImageSwiftUI

struct ContentView: View {

    @ObservedObject var presenter: MainPresenter

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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(presenter: MainPresenter(auth: FakeSpotifyAuthManager(),
//                                             userManager: FakeUserManager(),
//                                             playlistManager: FakePlaylistsManager(),
//                                             playerManager: FakePlayerManager(),
//                                             systemPublishers: SystemPublishersImplementation()))
//    }
//}

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
