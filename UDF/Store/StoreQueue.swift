//===--- StoreQueue.swift -------------------------------------------------===//
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

/// A class that provides a serial queue for store operations, ensuring that only one operation
/// is executed at a time.
final class StoreQueue: OperationQueue {
    
    /// Initializes a new `StoreQueue` with a maximum concurrency of one and a user-interactive quality of service.
    override init() {
        super.init()
        maxConcurrentOperationCount = 1
        name = "StoreQueue"
        qualityOfService = .userInteractive
    }
}

/// An abstract base class representing an asynchronous operation.
/// This class manages the operation's execution state and allows subclasses to define
/// custom asynchronous work.
open class AsynchronousOperation: Operation {
    
    /// Indicates that the operation is asynchronous.
    public override var isAsynchronous: Bool {
        return true
    }
    
    /// Indicates if the operation is currently executing.
    public override var isExecuting: Bool {
        return state == .executing
    }
    
    /// Indicates if the operation has finished executing.
    public override var isFinished: Bool {
        return state == .finished
    }
    
    /// Starts the operation and updates the state accordingly.
    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }
    
    /// The main entry point for the operation.
    open override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
    }
    
    /// Marks the operation as finished.
    public func finish() {
        state = .finished
    }
    
    // MARK: - State Management
    
    /// An enumeration representing the state of an asynchronous operation.
    public enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        
        /// Returns the key path for KVO notifications.
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }
    
    /// The current state of the operation. This is a thread-safe property.
    public var state: State {
        get {
            stateQueue.sync {
                return stateStore
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


final class StoreOperation: AsynchronousOperation {
    var priority: Priority
    var closure: () async -> Void
    var task: Task<Void, Never>? = nil

    init(priority: Priority, closure: @escaping () async -> Void) {
        self.priority = priority
        self.closure = closure
        super.init()
        self.queuePriority = priority.queuePriority
    }

    override func main() {
        self.task = Task.detached(priority: priority.taskPriority) { [weak self] in
            await self?.closure()
            self?.finish()
        }
    }

    override func finish() {
        self.task = nil
        super.finish()
    }

    override func cancel() {
        self.task?.cancel()
        self.task = nil
        super.cancel()
    }
}

// MARK: - StoreOperation.Priority
extension StoreOperation {
    enum Priority {
        case `default`, userInteractive

        var taskPriority: TaskPriority {
            switch self {
            case .default: return .high
            case .userInteractive: return .userInteractive
            }
        }

        var queuePriority: Operation.QueuePriority {
            switch self {
            case .default: return .normal
            case .userInteractive: return .veryHigh
            }
        }

        init(_ actionPriority: ActionPriority) {
            switch actionPriority {
            case .default: self = .default
            case .userInteractive: self = .userInteractive
            }
        }
    }
}
