//
//  WebAuth.swift
//

import AuthenticationServices
import CEFSpotifyCore
import Combine

class WebAuthManager: WebAuth {
    func executeRequest<T>(_ urlRequest: URLRequest) -> AnyPublisher<T, Error> where T: Codable {
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, _ in try JSONDecoder().decode(T.self, from: data) }
            .eraseToAnyPublisher()
    }

    let presentationContextProvider = ShimViewController()

    func executeLogin(url: URL, callbackURLScheme: String, callback: @escaping (Result<URL, Error>) -> Void) {
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
