//
//  Debouncer.swift
//  
//
//  Created by Max Kuznetsov on 16.02.2021.
//

import Foundation

final class Debouncer<T> {
    private(set) var value: T?
    private var valueTimestamp: Date = Date()
    private var interval: TimeInterval
    private var queue: DispatchQueue
    private var callbacks: [(T) -> ()] = []
    private var debounceWorkItem: DispatchWorkItem = DispatchWorkItem {}
    
    init(_ interval: TimeInterval, on queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }
    
    func receive(_ value: T) {
        self.value = value
        dispatchDebounce()
    }
    
    func on(throttled: @escaping (T) -> ()) {
        self.callbacks.append(throttled)
    }
}

// MARK: - Help Methods
private extension Debouncer {
    
    func dispatchDebounce() {
        self.valueTimestamp = Date()
        self.debounceWorkItem.cancel()
        self.debounceWorkItem = DispatchWorkItem { [weak self] in
            self?.onDebounce()
        }
        queue.asyncAfter(deadline: .now() + interval, execute: debounceWorkItem)
    }
    
    func onDebounce() {
        if (Date().timeIntervalSince(self.valueTimestamp) > interval) {
            sendValue()
        }
    }
    
    func sendValue() {
        if let value = self.value { callbacks.forEach { $0(value) } }
    }
}

