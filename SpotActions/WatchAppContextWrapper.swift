//
// WatchMessageWrapper.swift
//

import Foundation
import CEFSpotifyCore

class WatchAppContextWrapper {

    enum Keys: String {
        case trackName = "tN"
        case artists = "tA"
        case albumUrl = "tI"
        case isPlaying = "p"
    }

    var message = [String: Any]()

    var trackName: String? {
        get { message[Keys.trackName.rawValue] as? String }
        set { message[Keys.trackName.rawValue] = newValue }
    }

    var trackArtistName: String? {
        get { message[Keys.artists.rawValue] as? String }
        set { message[Keys.artists.rawValue] = newValue }
    }

    var trackAlbumUrl: String? {
        get { message[Keys.albumUrl.rawValue] as? String }
        set { message[Keys.albumUrl.rawValue] = newValue }
    }

    var isPlaying: Bool? {
        get { message[Keys.isPlaying.rawValue] as? Bool }
        set { message[Keys.isPlaying.rawValue] = newValue }
    }
}

extension AuthState {
    func toDictionary() -> [String: Any] {
        switch self {
        case .loggedIn(let token):
            return ["_t": "AuthState", "t": "loggedIn", "token": token.toDictionary()]
        default:
            return ["_t": "AuthState"]
        }
    }

    public init(from message: [String: Any]) throws {
        guard (message["_t"] as? String) == "AuthState" else {
            throw "Message not of type AuthState"
        }

        switch message["t"] as? String {
        case "loggedIn":
            guard let tokenDic = message["token"] as? [String: Any],
                  let token = try? TokenResponse(from: tokenDic) else {
                throw "Error parsing AuthState loggedIn message!"
            }
            self = .loggedIn(token: token)
        default:
            self = .notLoggedIn
        }
    }
}

extension TokenResponse {
    func toDictionary() -> [String: String?] {
        return [
            "_t": "TokenResponse",
            "aT": accessToken,
            "tT": tokenType,
            "s": scope,
            "rT": refreshToken
        ]
    }

    public init(from message: [String: Any]) throws {
        self.init()
        guard (message["_t"] as? String) == "TokenResponse" else {
            throw "Message not of type TokenResponse"
        }
        accessToken = message["aT"] as? String
        tokenType = message["tT"] as? String
        scope = message["s"] as? String
        refreshToken = message["rT"] as? String
    }
}
