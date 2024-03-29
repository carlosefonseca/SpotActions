//
//  SpotifyAuthManager.swift
//

import Combine
import Foundation

public protocol WebAuth {
    func executeLogin(url: URL, callbackURLScheme: String, callback: @escaping (Result<URL, Error>) -> Void)
//    func executeRequest<T>(_ urlRequest: URLRequest) -> AnyPublisher<T, Error> where T: Codable
}

public protocol SpotifyAuthManager {
    func login()
    var state: AuthState { get }
    var statePublisher: AnyPublisher<AuthState, Never> { get }
    func logout()
    func refreshToken() -> AnyPublisher<TokenResponse, RefreshTokenError>
}

public enum AuthState: Equatable {
    case notLoggedIn
    case loggedIn(token: TokenResponse)
    case error(_ error: String?)
}

public enum RefreshTokenError: Error, LocalizedError {
    case noLogin
    case requestError(error: UrlRequesterError)
    case otherError(_ error: Error)
    case other(message: String)

    public var errorDescription: String? {
        switch self {
        case .noLogin:
            return "No Login"
        case let .requestError(error):
            return "Request Error (\(error))"
        case let .otherError(error):
            return "Error (\(error))"
        case let .other(message):
            return "Error (\(message))"
        }
    }
}

public final class SpotifyAuthManagerImplementation: ObservableObject, SpotifyAuthManager {

    lazy var authorizationUrl = URL(string: "https://accounts.spotify.com/authorize")!
    lazy var accessTokenUrl = URL(string: "https://accounts.spotify.com/api/token")!
    lazy var scopes = "playlist-read-private playlist-read-collaborative playlist-modify-private playlist-modify-public user-read-email user-read-recently-played user-read-private user-read-playback-state user-modify-playback-state"

    var clientId = ""
    var clientSecret = ""

    lazy var authUrlState = UUID().uuidString

    let redirectUri = "spotactions://auth"
    let callbackScheme = "spotactions"

    private let defaultAccountKey = "defaultAccount"

    var bag = Set<AnyCancellable>()

    lazy var fullAuthorizationUrl: URL = {
        let x = URLComponents(url: authorizationUrl, resolvingAgainstBaseURL: false)
        var y = URLComponents(string: "https://accounts.spotify.com/authorize")!
        y.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "state", value: authUrlState),
            URLQueryItem(name: "scope", value: scopes)
        ]
        return y.url!
    }()

    lazy var authHeader = "\(clientId):\(clientSecret)".data(using: String.Encoding.utf8)?.base64EncodedString()

    var webAuthManager: WebAuth
    var credentialStore: CredentialStore
    let requester: URLRequester

    let decoder: JSONDecoder

    public init(webAuthManager: WebAuth, credentialStore: CredentialStore, requester: URLRequester, clientId: String, clientSecret: String) {
        self.webAuthManager = webAuthManager
        self.credentialStore = credentialStore
        self.requester = requester
        self.clientId = clientId
        self.clientSecret = clientSecret
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let token = getToken() else { return }
        state = .loggedIn(token: token)
    }

    @Published public var state: AuthState = .notLoggedIn

    public var statePublisher: AnyPublisher<AuthState, Never> {
        $state.removeDuplicates().eraseToAnyPublisher()
    }

    public func login() {

        webAuthManager.executeLogin(url: fullAuthorizationUrl, callbackURLScheme: callbackScheme) { result in
            switch result {
            case let .success(url):
                let token = NSURLComponents(string: url.absoluteString)?.queryItems?.filter { $0.name == "code" }.first

                // Do what you now that you've got the token, or use the callBack URL
                print(token ?? "No OAuth Token")

                guard let oauthToken = token?.value else {
                    self.state = .error("No OAuth Token")
                    return
                }

                self.swapCodeForToken(token: oauthToken)

            case let .failure(error):
                print(error)
                self.state = .error(error.localizedDescription)
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

        guard let authHeader = self.authHeader else {
            print("no auth header!")
            return
        }

        urlRequest.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")

        let bodyStr = "grant_type=authorization_code&code=\(token)&redirect_uri=\(redirectUri)"

        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = bodyStr.data(using: .utf8)

        print(urlRequest)

        requester.request(urlRequest: urlRequest)
            .decode(type: TokenResponse.self, decoder: decoder)
            .print()
            .sink { completion in
                if case let .failure(error) = completion {
                    self.state = .error(error.localizedDescription)
                }
            } receiveValue: { (value: TokenResponse) in
                do {
                    let jsonEncoder = JSONEncoder()
                    jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
                    let encodedValue = try jsonEncoder.encode(value)
                    self.storeToken(data: encodedValue)
                    self.state = .loggedIn(token: value)
                } catch {
                    self.state = .error(error.localizedDescription)
                }
            }.store(in: &bag)
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
            let parsedData = try decoder.decode(TokenResponse.self, from: existingData)
            guard parsedData.accessToken != nil else { return nil }
            return parsedData
        } catch {
            print(error)
            return nil
        }
    }

    func createRefreshTokenUrlRequest() -> AnyPublisher<URLRequest, RefreshTokenError> {
        statePublisher
            .first()
            .tryMap { existingToken -> URLRequest in

                guard
                    case let .loggedIn(token) = existingToken,
                    let refreshToken = token.refreshToken
                else {
                    print("no refresh token!")
                    self.state = .notLoggedIn
                    throw RefreshTokenError.noLogin
                }

                let url = self.accessTokenUrl
                var urlRequest = URLRequest(url: url)

                guard let authHeader = self.authHeader else {
                    print("no auth header!")
                    throw RefreshTokenError.noLogin
                }

                urlRequest.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")

                let bodyStr = "grant_type=refresh_token&refresh_token=\(refreshToken)"

                urlRequest.httpMethod = "POST"
                urlRequest.httpBody = bodyStr.data(using: .utf8)

                print(urlRequest)

                return urlRequest
            }.mapError { error -> RefreshTokenError in

                if let refreshTokenError = error as? RefreshTokenError {
                    return refreshTokenError
                } else {
                    return RefreshTokenError.otherError(error)
                }
            }
            .print("SpotifyAuthManager.createRefreshTokenUrlRequest")
            .eraseToAnyPublisher()
    }

    private func requestRefreshToken(urlRequest: URLRequest) -> AnyPublisher<TokenResponse, RefreshTokenError> {
        requester.request(urlRequest: urlRequest)
            .mapError { RefreshTokenError.requestError(error: $0) }
            .decode(type: TokenResponse.self, decoder: decoder).eraseToAnyPublisher()
            .mapError { $0 as? RefreshTokenError ?? RefreshTokenError.otherError($0) }
            .eraseToAnyPublisher()
    }

    public func refreshToken() -> AnyPublisher<TokenResponse, RefreshTokenError> {
        createRefreshTokenUrlRequest()
            .flatMap { self.requestRefreshToken(urlRequest: $0) }
            .eraseToAnyPublisher()
            .print("SpotifyAuthManager.refreshToken")
            .handleEvents(receiveOutput: { value in
                self.state = .loggedIn(token: value)
            }, receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.state = .error(error.localizedDescription)
                }
            })
            .eraseToAnyPublisher()
    }
}

public struct TokenResponse: Codable, Equatable {
    public var accessToken: String?
    public var tokenType: String?
    public var scope: String?
    public var expiresIn: Int?
    public var refreshToken: String?

    public init() {}
}

public struct AuthError: Error, Codable, LocalizedError {
    var error: String?
    var error_description: String?

    public var errorDescription: String? {
        error_description ?? error ?? "Unknown auth error"
    }
}
