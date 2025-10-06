//===--- StoreQueue.swift -------------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A class that provides a serial queue for store operations, ensuring that only one operation
/// is executed at a time.
final class StoreQueue: OperationQueue, @unchecked Sendable {
    /// Initializes a new `StoreQueue` with a maximum concurrency of one and a user-interactive quality of service.
    override init() {
        super.init()
        maxConcurrentOperationCount = 2
        name = "StoreQueue"
        qualityOfService = .userInteractive
    }
}

/// An abstract base class representing an asynchronous operation.
/// This class manages the operation's execution state and allows subclasses to define
/// custom asynchronous work.
class AsynchronousOperation: Operation {
    /// Indicates that the operation is asynchronous.
    override var isAsynchronous: Bool {
        true
    }

    /// Indicates if the operation is currently executing.
    override var isExecuting: Bool {
        state == .executing
    }

    /// Indicates if the operation has finished executing.
    override var isFinished: Bool {
        state == .finished
    }

    /// Starts the operation and updates the state accordingly.
    override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }

    /// The main entry point for the operation.
    override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
    }

    /// Marks the operation as finished.
    func finish() {
        state = .finished
    }

    // MARK: - State Management

    /// An enumeration representing the state of an asynchronous operation.
    enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"

        /// Returns the key path for KVO notifications.
        fileprivate var keyPath: String { "is" + self.rawValue }
    }

    /// The current state of the operation. This is a thread-safe property.
    var state: State {
        get {
            stateQueue.sync {
                stateStore
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) {
                stateStore = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }

    /// A concurrent queue used to ensure thread-safe access to `stateStore`.
    private let stateQueue = DispatchQueue(label: "AsynchronousOperation State Queue", attributes: .concurrent)

    /// The non-thread-safe storage for the operation's state.
    private var stateStore: State = .ready
}
