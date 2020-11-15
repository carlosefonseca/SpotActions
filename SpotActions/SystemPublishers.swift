//
// SystemPublishers.swift
//

import UIKit
import Combine

protocol SystemPublishers {
    var appIsInForeground: AnyPublisher<Bool, Never> { get }
}

class SystemPublishersImplementation: SystemPublishers {

    private let foregroundSubscriber = NotificationCenter.default
        .publisher(for: UIApplication.didBecomeActiveNotification)
        .map { _ in true }

    private let bgSubscriber = NotificationCenter.default
        .publisher(for: UIApplication.willResignActiveNotification)
        .map { _ in false }

    var appIsInForeground: AnyPublisher<Bool, Never> {
        Publishers.Merge(foregroundSubscriber, bgSubscriber)
            .share()
            .eraseToAnyPublisher()
    }
}
