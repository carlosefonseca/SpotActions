//
//  SpotifyUserProfile.swift
//

import Foundation
import Combine

public struct User: Codable {
    public var country: String?
    public var display_name: String?
    public var email: String?
    //   public var external_urls : [String:String]?
    //   public var followers : String?
    public var href: String?
    public var id: String?
    //   public var images : String?
    public var product: String?
    public var type: String?
    public var uri: String?
}

extension SpotifyWebApi.UserProfile {

    public typealias Response = User

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
    public func user(callback: @escaping (Result<User, SpotifyRequestError>) -> Void) {
        let request = SpotifyWebApi.UserProfile.Request(baseURL: baseURL)
        requestManager.execute(request: request) { (result: Result<User, SpotifyRequestError>) in
            callback(result)
        }
    }
}
