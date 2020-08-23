//
//  SpotifyUserProfile.swift
//

import Foundation
import Combine

extension SpotifyWebApi.UserProfile {

    public typealias Response = UserJSON

    public struct Request: URLRequestable {

        public var urlRequest: URLRequest

        init(baseURL: URL) {
            urlRequest = URLRequest(url: URL(string: "/v1/me", relativeTo: baseURL)!)
        }
    }
}

public protocol SpotifyUserProfileGateway {
    func user(callback: @escaping (Result<SpotifyWebApi.UserProfile.Response, SpotifyRequestError>) -> Void)
}

public class SpotifyUserProfileGatewayImplementation: BaseSpotifyGateway, SpotifyUserProfileGateway {
    public func user(callback: @escaping (Result<UserJSON, SpotifyRequestError>) -> Void) {
        let request = SpotifyWebApi.UserProfile.Request(baseURL: baseURL)
        requestManager.execute(request: request) { (result: Result<UserJSON, SpotifyRequestError>) in
            callback(result)
        }
    }
}
