//
//  SpotifyAuthManager.swift
//

import Foundation

public protocol WebAuth {
    func execute(url: URL, callbackURLScheme: String, callback: @escaping (Result<URL, Error>) -> Void)
}

public protocol SpotifyAuthManager {
    func login()
    var state: AuthState { get }
    var statePublished: Published<AuthState> { get }
    var statePublisher: Published<AuthState>.Publisher { get }
    func logout()
    func refreshToken(completion: @escaping (Error?) -> Void)
}

public enum AuthState {
    case notLoggedIn
    case loggedIn(token: TokenResponse)
    case error(_ error: Error?)
}

// public struct AuthError : Error {
//    let error:Error
// }
// public enum AuthError: Error {
//    case someError(error: Error)
// }

public final class SpotifyAuthManagerImplementation: ObservableObject, SpotifyAuthManager {

    lazy var authorizationUrl = { URL(string: "https://accounts.spotify.com/authorize")! }()
    lazy var accessTokenUrl = { URL(string: "https://accounts.spotify.com/api/token")! }()
    lazy var scopes = { "playlist-read-private playlist-read-collaborative playlist-modify-private playlist-modify-public user-read-email user-read-recently-played user-read-private user-read-playback-state user-modify-playback-state" }()

    lazy var clientId = { "" }()
    lazy var clientSecret = { "" }()

    lazy var authUrlState = { UUID().uuidString }()

    let redirectUri = "spotactions://auth"

    private let defaultAccountKey = "defaultAccount"

    lazy var fullAuthorizationUrl: URL = {
        let x = URLComponents(url: authorizationUrl, resolvingAgainstBaseURL: false)
        var y = URLComponents(string: "https://accounts.spotify.com/authorize")!
        y.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "state", value: authUrlState),
            URLQueryItem(name: "scope", value: scopes),
        ]
        return y.url!
    }()

    lazy var authHeader = { "\(clientId):\(clientSecret)".data(using: String.Encoding.utf8)?.base64EncodedString() }()

    var webAuthManager: WebAuth
    var credentialStore: CredentialStore

    public init(webAuthManager: WebAuth, credentialStore: CredentialStore) {
        self.webAuthManager = webAuthManager
        self.credentialStore = credentialStore
        guard let token = getToken() else { return }
        state = .loggedIn(token: token)
    }

    @Published public var state: AuthState = .notLoggedIn
    public var statePublished: Published<AuthState> { _state }
    public var statePublisher: Published<AuthState>.Publisher { $state }

    public func login() {

        webAuthManager.execute(url: fullAuthorizationUrl, callbackURLScheme: redirectUri) { result in
            switch result {
            case .success(let url):
                let token = NSURLComponents(string: url.absoluteString)?.queryItems?.filter { $0.name == "code" }.first

                // Do what you now that you've got the token, or use the callBack URL
                print(token ?? "No OAuth Token")

                guard let oauthToken = token?.value else { return }
                self.swapCodeForToken(token: oauthToken)

            case .failure(let error):
                print(error)
            }
        }
    }

    func clearStoredToken() {
        try? credentialStore.delete(account: defaultAccountKey)
    }

    public func logout() {
        clearStoredToken()
        state = .notLoggedIn
    }

    private func swapCodeForToken(token: String) {
        let url = accessTokenUrl
        var urlRequest = URLRequest(url: url)

        guard let authHeader = self.authHeader else { print("no auth header!"); return }

        urlRequest.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")

        let bodyStr = "grant_type=authorization_code&code=\(token)&redirect_uri=\(redirectUri)"

        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = bodyStr.data(using: .utf8)

        print(urlRequest)

        URLSession.shared.dataTask(with: urlRequest) { [self] data, response, error in
            if (error as NSError?)?.isNetworkConnectionError() != nil {
                clearStoredToken()
                self.state = .error(error)
                return
            }

            // Check if an error happened while making the request
            if let error = error {
                clearStoredToken()
                self.state = .error(error)
                return
            }

            // Check if we have a `HTTPURLResponse`
            guard let httpUrlResponse = response as? HTTPURLResponse else {
                clearStoredToken()
                self.state = .error(error)
                return
            }

            // Check if response is success or a known error
            switch httpUrlResponse.type {
            case .success:

                do {
                    let token = try JSONDecoder().decode(TokenResponse.self, from: data!)
                    self.storeToken(data: data!)
                    self.state = .loggedIn(token: token)
                } catch {
                    clearStoredToken()
                    self.state = .error(error)
                }
                return

            case .unauthorized, .forbidden, .error, .other:
                clearStoredToken()
                do {
                    if let data = data {
                        let error = try JSONDecoder().decode(AuthError.self, from: data)
                        self.state = .error(error)
                    } else {
                        self.state = .error(error)
                    }
                } catch {
                    self.state = .error(error)
                }
            }
        }.resume()
    }

    private func storeToken(data: Data) {
        do {
            try credentialStore.set(value: data, account: defaultAccountKey)
        } catch {
            print(error)
        }
    }

    private func getToken() -> TokenResponse? {
        let data: Data?
        do {
            data = try credentialStore.get(account: defaultAccountKey)
        } catch {
            print(error)
            return nil
        }

        guard let existingData = data else { return nil }

        do {
            let parsedData = try JSONDecoder().decode(TokenResponse.self, from: existingData)
            guard parsedData.access_token != nil else { return nil }
            return parsedData
        } catch {
            print(error)
            return nil
        }
    }

    public func refreshToken(completion: @escaping (Error?) -> Void) {
        guard
            case .loggedIn(let token) = state,
            let refreshToken = token.refresh_token
        else { print("no refresh token!"); return }

        let url = accessTokenUrl
        var urlRequest = URLRequest(url: url)

        guard let authHeader = self.authHeader else { print("no auth header!"); return }

        urlRequest.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")

        let bodyStr = "grant_type=refresh_token&refresh_token=\(refreshToken)"

        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = bodyStr.data(using: .utf8)

        print(urlRequest)

        URLSession.shared.dataTask(with: urlRequest) { [self] data, response, error in
            if (error as NSError?)?.isNetworkConnectionError() != nil {
                clearStoredToken()
                self.state = .error(error)
                completion(error)
                return
            }

            // Check if an error happened while making the request
            if let error = error {
                clearStoredToken()
                self.state = .error(error)
                completion(error)
                return
            }

            // Check if we have a `HTTPURLResponse`
            guard let httpUrlResponse = response as? HTTPURLResponse else {
                clearStoredToken()
                self.state = .error(error)
                completion(error)
                return
            }

            // Check if response is success or a known error
            switch httpUrlResponse.type {
            case .success:

                do {
                    let token = try JSONDecoder().decode(TokenResponse.self, from: data!)
                    self.storeToken(data: data!)
                    self.state = .loggedIn(token: token)
                    completion(nil)
                } catch {
                    clearStoredToken()
                    self.state = .error(error)
                    completion(error)
                }
                return

            case .unauthorized, .forbidden, .error, .other:
                clearStoredToken()
                do {
                    if let data = data {
                        let error = try JSONDecoder().decode(AuthError.self, from: data)
                        self.state = .error(error)
                        completion(error)
                    } else {
                        self.state = .error(error)
                        completion(error)
                    }
                } catch {
                    self.state = .error(error)
                    completion(error)
                }
            }
        }.resume()
    }
}

public struct TokenResponse: Codable {
    var access_token: String?
    var token_type: String?
    var scope: String?
    var expires_in: Int?
    var refresh_token: String?

    public init() {}
}

public struct AuthError: Error, Codable, LocalizedError {
    var error: String?
    var error_description: String?

    public var errorDescription: String? {
        error_description ?? error ?? "Unknown auth error"
    }
}
