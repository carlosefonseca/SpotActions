//
// UrlSessionRequester.swift
//

import Foundation
import Combine

public class UrlSessionRequester: URLRequester {

    public init() {}

    public func request(urlRequest: URLRequest) -> AnyPublisher<Data, UrlRequesterError> {
        print(urlRequest.url!)
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .mapError { error -> UrlRequesterError in UrlRequesterError.systemError(error: error) }
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw UrlRequesterError.genericError(description: "Failed to get response")
                }

                switch httpResponse.type {
                case .success:
                    return data
                default:
                    print(String(data: data, encoding: .utf8)!)
                    throw UrlRequesterError.apiError(response: httpResponse, data: data)
                }
            }.mapError { error -> UrlRequesterError in
                if let urlRequestError = error as? UrlRequesterError {
                    return urlRequestError
                } else {
                    return UrlRequesterError.systemError(error: error)
                }
            }
            .handleEvents(receiveOutput: { data in
                if let str = String(data: data, encoding: .utf8) {
                    let splits = str.split(separator: "\n")
                    splits.forEach { line in
                        print("<-- \(line)")
                    }
                }
            })
            .eraseToAnyPublisher()
    }
}

extension NSError {
    func isNetworkConnectionError() -> Bool {
        let networkErrors = [NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet]

        return domain == NSURLErrorDomain && networkErrors.contains(code)
    }
}

public extension HTTPURLResponse {

    var isSuccess: Bool {
        return (200...299).contains(statusCode)
    }

    var isUnauthorized: Bool {
        return statusCode == 401
    }

    var isNotFound: Bool {
        return statusCode == 404
    }

    var isForbidden: Bool {
        return statusCode == 403
    }

    var isServerError: Bool {
        return (500..<600).contains(statusCode)
    }

    var type: ResponseType {
        if isSuccess { return .success }
        if isUnauthorized { return .unauthorized }
        if isForbidden { return .forbidden }
        if isServerError { return .error }
        return .other
    }
}

public enum ResponseType: String, RawRepresentable, CustomStringConvertible, Equatable {
    case success
    case unauthorized
    case forbidden
    case error
    case other

    public var description: String { rawValue }
}
