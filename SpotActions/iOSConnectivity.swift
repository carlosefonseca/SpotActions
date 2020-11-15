//
// iOSConnectivity.swift
//

import Foundation
import WatchConnectivity

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

    func sendWatchMessage() {
        let currentTime = CFAbsoluteTimeGetCurrent()

        // if less than half a second has passed, bail out
        if lastMessage + 0.5 > currentTime {
            return
        }

        // send a message to the watch if it's reachable
        if WCSession.default.isReachable {
            // this is a meaningless message, but it's enough for our purposes
            let message = ["Message": "Hello"]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }

        // update our rate limiting property
        lastMessage = CFAbsoluteTimeGetCurrent()
    }
}
