//
// FakeUrlRequester.swift
//

import Foundation
import CEFSpotifyCore
import Combine

public class FakeUrlRequester: URLRequester {
    public init() {}

    public var responses = [Result<Data, UrlRequesterError>]()

    public func request(urlRequest: URLRequest) -> AnyPublisher<Data, UrlRequesterError> {
        return Deferred {
            Future<Data, UrlRequesterError> { promise in

                guard self.responses.isEmpty == false else {
                    promise(.failure(UrlRequesterError.genericError(description: "No data to send!")))
                    return
                }

                let response = self.responses.removeFirst()

                switch response {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
