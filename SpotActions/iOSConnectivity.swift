//
// iOSConnectivity.swift
//

import Foundation
import WatchConnectivity
import CEFSpotifyCore
import Combine

public class iOSConnectivity: NSObject, WCSessionDelegate {

    var bag = Set<AnyCancellable>()

    var authManager: SpotifyAuthManager
    @Published var auth: [String: Any] = AuthState.notLoggedIn.toDictionary()
    @Published var playback = PlaybackViewModel()

    init(authManager: SpotifyAuthManager) {
        self.authManager = authManager
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()

            let a = authManager.statePublisher.removeDuplicates()

            let b = $playback//.removeDuplicates()

            Publishers.CombineLatest(a, b)
                .map { (a, b) -> [String: Any] in ["auth": a.toDictionary(), "pb": b.toDictionary()] }
                .sink { data in
                    do {
                        print("WK iOS updateApplicationContext")
                        try WCSession.default.updateApplicationContext(data)
                    } catch {
                        print("WK iOS ERROR \(error)")
                    }
                }.store(in: &bag)
        } else {
            print("WK iOS: Not supported!")
        }
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("WK iOS: sessionDidBecomeInactive")
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        print("WK iOS: sessionDidDeactivate")
        WCSession.default.activate()
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WK iOS: activationDidCompleteWith")
    }

    func sendWatchMessage(data: CurrentlyPlayingJSON?) {
        playback = PlaybackViewModel(from: data)
//        guard WCSession.default.isReachable else {
//            print("WK: Not Reachable")
//            return
//        }
//
//        let m = WatchAppContextWrapper()
//
//        if let data = data {
//            if let item = data.item {
//
//                m.trackName = item.title
//                m.trackArtistName = item.artistNames.joined(separator: ", ")
//                m.trackAlbumUrl = item.albumArtUrl?.absoluteString
//            }
//            m.isPlaying = data.isPlaying
//        }
//
//        try? WCSession.default.updateApplicationContext(m.message)
    }
}
