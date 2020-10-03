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

public extension String {
    func contains(regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

extension Sequence {
    func toArray() -> [Iterator.Element] {
        Array(self)
    }
}

extension Sequence where Iterator.Element: Hashable {
    func toSet() -> Set<Iterator.Element> {
        Set(self)
    }
}
