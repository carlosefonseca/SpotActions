//
// iOSConnectivity.swift
//

import Foundation
import WatchConnectivity
import CEFSpotifyCore

public class iOSConnectivity: NSObject, WCSessionDelegate {

    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    var lastMessage: CFAbsoluteTime = 0

    var encoder = JSONEncoder()

    func sendWatchMessage(data: CurrentlyPlayingJSON?) {
        guard WCSession.default.isReachable else {
            print("WK: Not Reachable")
            return
        }

        let m = WatchMessageWrapper()

        if let data = data {
            if let item = data.item {

                m.trackName = item.title
                m.trackArtistName = item.artistNames.joined(separator: ", ")
                m.trackAlbumUrl = item.albumArtUrl?.absoluteString
            }
            m.isPlaying = data.isPlaying
        }

        try? WCSession.default.updateApplicationContext(m.message)
    }
}
