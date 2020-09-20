//
// Extensions.swift
//

import Foundation
import Combine

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

public func errorToPublisher<E, O>(error: E?, outputType: O.Type) -> AnyPublisher<O, E> where E: Error {
    guard let error = error else {
        return Empty(completeImmediately: true, outputType: outputType, failureType: E.self).eraseToAnyPublisher()
    }

    return Fail(outputType: outputType, failure: error).eraseToAnyPublisher()
}
