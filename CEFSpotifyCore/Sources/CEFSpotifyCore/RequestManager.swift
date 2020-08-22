//
//  RequestManager.swift
//

import Foundation


public protocol URLRequestable {
    var urlRequest: URLRequest { get }
}

public protocol RequestManager {
    func execute<T>(request: URLRequestable, completion: @escaping (Result<T, SpotifyRequestError>) -> Void) where T: Decodable
    //    func execute(request: URLRequestable, completion: @escaping (Error?) -> Void)
    //    func execute(request: URLRequest, completion: @escaping (Result<(HTTPURLResponse, Data?)>) -> Void)
}


public struct SpotifyWebApiError: Error, Decodable {
    let error: SpotifyRegularError
}
