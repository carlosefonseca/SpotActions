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
    func user() -> AnyPublisher<UserJSON, Error>
}

public class SpotifyUserProfileGatewayImplementation: BaseSpotifyGateway, SpotifyUserProfileGateway {
    public func user() -> AnyPublisher<UserJSON, Error> {
        let request = SpotifyWebApi.UserProfile.Request(baseURL: baseURL)
        return requestManager.execute(request: request)
            .decode(type: SpotifyWebApi.UserProfile.Response.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
