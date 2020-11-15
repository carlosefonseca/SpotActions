//
// WatchConnect.swift
//

import Foundation
import WatchConnectivity

class WatchConnect: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session \(session) activationDidCompleteWith \(activationState)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("session \(session) didReceiveMessage \(message)")
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
