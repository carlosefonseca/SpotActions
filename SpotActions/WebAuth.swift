//
//  WebAuth.swift
//

import AuthenticationServices
import CEFSpotifyCore

class WebAuthManager: WebAuth {

    let presentationContextProvider = ShimViewController()

    func execute(url: URL, callbackURLScheme: String, callback: @escaping (Result<URL, Error>) -> Void) {
        let webAuthSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { successURL, error in

            guard error == nil else {
                callback(.failure(error!))
                return
            }

            callback(.success(successURL!))
        }
        webAuthSession.presentationContextProvider = presentationContextProvider

        // Kick it off
        webAuthSession.start()
    }
}

class ShimViewController: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Perhaps I don't need the window object at all, and can just use:
        // return ASPresentationAnchor()
        return UIApplication.shared.windows.last!
    }
}
