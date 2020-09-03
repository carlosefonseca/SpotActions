//
// FakeWebAuth.swift
//

import Foundation
import CEFSpotifyCore
import Combine

struct FakeWebAuth: WebAuth {

    let loginResult: Result<URL, Error>
    let requestResult: Result<Codable, Error>

    func executeLogin(url: URL, callbackURLScheme: String, callback: @escaping (Result<URL, Error>) -> Void) {
        callback(loginResult)
    }

    func executeRequest<T>(_ urlRequest: URLRequest) -> AnyPublisher<T, Error> where T: Codable {
        return Future { promise in
            switch requestResult {
            case .success(let data):
                promise(.success(data as! T))
            case .failure(let error):
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
