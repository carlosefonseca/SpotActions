//
//  SpotifyApiGateway.swift
//

import Foundation

public protocol WebApiError: Error {}

public struct SpotifyRegularError: Codable {
    let status: Int
    let message: String
}

public enum SpotifyRequestError: WebApiError, LocalizedError {
    case requestError(error: Error?)
    case networkError(error: Error)
    case httpError(error: ResponseType, data: Data?)
    case parseError(error: Error)
    case apiError(error: ResponseType, data: SpotifyRegularError)
    case noLogin
    case unauthorized(error: ResponseType)
    case otherError(message: String)
}

public enum SpotifyWebApi {
    public enum UserProfile {}
    public enum Playlists {}
}

public class BaseSpotifyGateway {
    let baseURL: URL
    let requestManager: RequestManager

    public init(baseURL: URL, requestManager: RequestManager) {
        self.baseURL = baseURL
        self.requestManager = requestManager
    }
}
