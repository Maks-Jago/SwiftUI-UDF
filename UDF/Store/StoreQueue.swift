//
//  StoreQueue.swift
//  
//
//  Created by Max Kuznetsov on 07.10.2021.
//

import Foundation

final class StoreQueue: OperationQueue {

    override init() {
        super.init()
        maxConcurrentOperationCount = 1
        name = "StoreQueue"
        qualityOfService = .userInteractive
    }
}

open class AsynchronousOperation: Operation {
    public override var isAsynchronous: Bool {
        return true
    }

    public override var isExecuting: Bool {
        return state == .executing
    }

    public override var isFinished: Bool {
        return state == .finished
    }

    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }

    open override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
    }

    public func finish() {
        state = .finished
    }

    // MARK: - State management

    public enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }

    /// Thread-safe computed state value
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

    private let stateQueue = DispatchQueue(label: "AsynchronousOperation State Queue", attributes: .concurrent)

    /// Non thread-safe state storage, use only with locks
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
