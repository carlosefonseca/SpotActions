//
// WatchSystemPublishers.swift
//

import WatchKit
import Combine

class WatchSystemPublishers: SystemPublishers {

    private let foregroundSubscriber = NotificationCenter.default
        .publisher(for: Notification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"))
        .map { _ in true }

    private let bgSubscriber = NotificationCenter.default
        .publisher(for: Notification.Name(rawValue: "UIApplicationDidEnterBackgroundNotification"))
        .map { _ in false }

    var appIsInForeground: AnyPublisher<Bool, Never> {
        Publishers.Merge(foregroundSubscriber, bgSubscriber)
            .share()
            .eraseToAnyPublisher()
    }
}
