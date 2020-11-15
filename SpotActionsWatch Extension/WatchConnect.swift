//
// WatchConnect.swift
//

import Foundation
import WatchConnectivity

class WatchConnect: NSObject, WCSessionDelegate {

    @Published var track: TrackViewModel?

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session \(session) activationDidCompleteWith \(activationState)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("GOT MESSAGE")
        handleUpdate(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("GOT APP CONTEXT")
        handleUpdate(applicationContext)
    }

    fileprivate func handleUpdate(_ message: [String: Any]) {

        let m = WatchMessageWrapper()
        m.message = message

        print("Track name: \(m.trackName ?? "-")")
        print("Track Artists: \(m.trackArtistName ?? "-")")
        print("Is Playing: \(m.isPlaying ?? false)")

        track = TrackViewModel(title: m.trackName ?? "", artist: m.trackArtistName ?? "", imageUrl: URL(string: m.trackAlbumUrl ?? ""))
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
