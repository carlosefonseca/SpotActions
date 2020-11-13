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

extension DecodingError.Context {
    var shortCodingPath: String {
        guard !codingPath.isEmpty else { return "root object" }
        return codingPath.map { key in
            key.intValue != nil ? "[\(key.intValue!)]" : ".\(key.stringValue)"
        }.joined()
    }
}

extension DecodingError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case DecodingError.dataCorrupted(let context):
            return "Data Corrupted: \(context)"
        case DecodingError.keyNotFound(let key, let context):
            return "Key '\(key.stringValue)' not found on \(context.shortCodingPath) (\(context.debugDescription))"
        case DecodingError.valueNotFound(let value, let  context):
            return "Value '\(value)' not found on path \(context.shortCodingPath) (\(context.debugDescription))"
        case DecodingError.typeMismatch(let type, let context):
            return "Type '\(type)' mismatch on path \(context.shortCodingPath) (\(context.debugDescription))"
        default:
            return "\(self)"
        }
    }
}
