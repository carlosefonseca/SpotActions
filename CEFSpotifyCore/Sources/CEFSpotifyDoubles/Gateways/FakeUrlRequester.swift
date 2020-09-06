//
// FakeUrlRequester.swift
//

import Foundation
import CEFSpotifyCore
import Combine

public class FakeUrlRequester: URLRequester {

    public init() {}

    public var responses = [Result<Any, UrlRequesterError>]()

    public func request<T>(urlRequest: URLRequest) -> AnyPublisher<T, UrlRequesterError> where T: Decodable {
        return Deferred {
            Future<T, UrlRequesterError> { promise in

                guard self.responses.isEmpty == false else {
                    promise(.failure(UrlRequesterError.genericError(description: "No data to send!")))
                    return
                }

                let response = self.responses.removeFirst()

                switch response {
                case .success(let value):
                    promise(.success(value as! T))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
