//
// WatchConnect.swift
//

import Foundation
import WatchConnectivity
import CEFSpotifyCore

class WatchConnect: NSObject, WCSessionDelegate {

    @Published var auth: AuthState?
    @Published var playback: PlaybackViewModel?

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WK Watch: session \(session) activationDidCompleteWith \(activationState)")
        handleUpdate( WCSession.default.applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("WK Watch: GOT MESSAGE")
        handleUpdate(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("WK Watch: GOT APP CONTEXT")
        handleUpdate(applicationContext)
    }

    fileprivate func handleUpdate(_ message: [String: Any]) {
        print("WK Watch: HandleUpdate \(message)")
        if let authMsg = message["auth"] as? [String: Any] {
            auth = try? AuthState(from: authMsg)

        }

        if let pbMsg = message["pb"] as? [String: Any] {
            playback = PlaybackViewModel(from: pbMsg)
        }
//
////        let m = WatchMessageWrapper()
////        m.message = message
//
//        print("Auth: \(auth)")
//        print("Track Artists: \(m.trackArtistName ?? "-")")
//        print("Is Playing: \(m.isPlaying ?? false)")
//
//        track = TrackViewModel(title: m.trackName ?? "", artist: m.trackArtistName ?? "", imageUrl: URL(string: m.trackAlbumUrl ?? ""))
    }

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
}
