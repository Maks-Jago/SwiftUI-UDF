//===--- Debouncer.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A utility class that debounces input, ensuring that the provided value is only processed
/// after a specified time interval has passed since the last input. This is particularly useful
/// in scenarios where frequent updates need to be limited, such as user typing in a text field.
///
/// - Parameters:
///   - T: The type of value to debounce.
final class Debouncer<T> {
    /// The latest received value.
    private(set) var value: T?
    
    /// Timestamp of the latest value received.
    private var valueTimestamp: Date = Date()
    
    /// The debounce interval.
    private var interval: TimeInterval
    
    /// The queue on which debounce operations are performed.
    private var queue: DispatchQueue
    
    /// Callbacks to be executed when the debounce interval passes.
    private var callbacks: [(T) -> ()] = []
    
    /// The work item used to manage debounce delays.
    private var debounceWorkItem: DispatchWorkItem = DispatchWorkItem {}
    
    /// Initializes a new `Debouncer` with the specified interval and dispatch queue.
    ///
    /// - Parameters:
    ///   - interval: The debounce interval in seconds.
    ///   - queue: The dispatch queue on which to perform debounce operations. Default is `.main`.
    init(_ interval: TimeInterval, on queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }
    
    /// Receives a new value and resets the debounce timer.
    ///
    /// - Parameter value: The value to be debounced.
    func receive(_ value: T) {
        self.value = value
        dispatchDebounce()
    }
    
    /// Adds a callback to be executed when the debounce interval passes.
    ///
    /// - Parameter throttled: The callback to execute with the debounced value.
    func on(throttled: @escaping (T) -> ()) {
        self.callbacks.append(throttled)
    }
}

// MARK: - Helper Methods
private extension Debouncer {
    
    /// Dispatches the debounce work item to run after the specified interval.
    func dispatchDebounce() {
        self.valueTimestamp = Date()
        self.debounceWorkItem.cancel()
        self.debounceWorkItem = DispatchWorkItem { [weak self] in
            self?.onDebounce()
        }
        queue.asyncAfter(deadline: .now() + interval, execute: debounceWorkItem)
    }
    
    /// Called when the debounce interval has passed, executing the stored callbacks.
    func onDebounce() {
        if (Date().timeIntervalSince(self.valueTimestamp) > interval) {
            sendValue()
        }
    }
    
    /// Executes all callbacks with the debounced value.
    func sendValue() {
        if let value = self.value {
            callbacks.forEach { $0(value) }
        }
    }
}
