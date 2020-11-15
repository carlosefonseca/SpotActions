//
// SystemPublishers.swift
//

import UIKit
import Combine

protocol SystemPublishers {
    var appIsInForeground: AnyPublisher<Bool, Never> { get }
}

