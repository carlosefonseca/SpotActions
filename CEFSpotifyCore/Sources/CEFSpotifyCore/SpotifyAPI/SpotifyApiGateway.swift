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

    public var errorDescription: String? {
        switch self {
        case .requestError(let error):
            return error?.localizedDescription ?? "Error while performing a request"
        case .networkError(let error):
            return error.localizedDescription
        case .httpError(let error, _):
            return error.description
        case .parseError(let error):
            return error.localizedDescription
        case .apiError(let error, _):
            return error.description
        case .noLogin:
            return "Not logged in."
        case .unauthorized(let error):
            return error.description
        case .otherError(let message):
            return message
        }
    }
}

public enum SpotifyWebApi {
    public enum UserProfile {}
    public enum Playlists {}
    public enum Player {}
}

public class BaseSpotifyGateway {
    let baseURL: URL
    let requestManager: RequestManager

    public init(baseURL: URL, requestManager: RequestManager) {
        self.baseURL = baseURL
        self.requestManager = requestManager
    }
}
