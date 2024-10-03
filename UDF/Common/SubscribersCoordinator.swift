//===--- SubscribersCoordinator.swift -----------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A type alias representing a subscriber that listens to state changes in the `AppReducer`.
/// - Parameters:
///   - oldState: The previous state before the change.
///   - newState: The new state after the change.
///   - animation: An optional animation that can be applied to the state change.
typealias StateSubscriber<State: AppReducer> = (_ oldState: State, _ newState: State, _ animation: Animation?) -> Void

/// An actor responsible for coordinating subscribers that respond to state changes.
actor SubscribersCoordinator<T> {
    /// A dictionary of subscribers, stored by unique keys.
    private var subscribers: [String: T] = [:]
    
    /// Adds a subscriber to the coordinator.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber to be added.
    ///   - key: An optional key to identify the subscriber. If not provided, a new UUID string is used.
    /// - Returns: The key associated with the added subscriber.
    @discardableResult
    func add(subscriber: T, for key: String = UUID().uuidString) -> String {
        subscribers[key] = subscriber
        return key
    }
    
    /// Removes a subscriber for the given key.
    ///
    /// - Parameter key: The key identifying the subscriber to be removed.
    func removeSubscriber(forKey key: String) {
        subscribers.removeValue(forKey: key)
    }
    
    /// Retrieves all the subscribers currently stored in the coordinator.
    ///
    /// - Returns: A collection of all subscribers.
    func allSubscibers() -> Dictionary<String, T>.Values {
        subscribers.values
    }
}
