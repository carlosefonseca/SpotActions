//
//  RequestManager.swift
//

import Foundation
import Combine

public protocol URLRequestable {
    var urlRequest: URLRequest { get }
}

public protocol RequestManager {
//    func execute<T>(request: URLRequestable, completion: @escaping (Result<T, SpotifyRequestError>) -> Void) where T: Decodable
    func execute<T>(request: URLRequestable) -> AnyPublisher<T, Error> where T: Codable
    func execute<T>(urlRequest: URLRequest) -> AnyPublisher<T, Error> where T: Codable

    //    func execute(request: URLRequestable, completion: @escaping (Error?) -> Void)
    //    func execute(request: URLRequest, completion: @escaping (Result<(HTTPURLResponse, Data?)>) -> Void)
}

public struct SpotifyWebApiError: Error, Codable {
    let error: SpotifyRegularError
}

public enum UrlRequesterError: Error {
    case systemError(error: Error)
    case genericError(description: String?)
    case apiError(response: HTTPURLResponse, data: Data)
    case parseError(error: Error)
}

public protocol URLRequester {
    func request<T>(urlRequest: URLRequest) -> AnyPublisher<T, UrlRequesterError> where T: Codable
}
