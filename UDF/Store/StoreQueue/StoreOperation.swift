//===--- StoreOperation.swift ----------------------------------------------===//
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

final class StoreOperation: AsynchronousOperation, @unchecked Sendable {
    var priority: Priority
    var closure: () async -> Void
    var task: Task<Void, Never>? = nil
    var deinitBlock: (() -> Void)?

    init(priority: Priority, deiinitBlock: (() -> Void)?, closure: @escaping () async -> Void) {
        self.priority = priority
        self.closure = closure
        self.deinitBlock = deiinitBlock
        super.init()
        self.queuePriority = priority.queuePriority
    }

    deinit {
        deinitBlock?()
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
            case .default: .high
            case .userInteractive: .userInteractive
            }
        }

        var queuePriority: Operation.QueuePriority {
            switch self {
            case .default: .normal
            case .userInteractive: .veryHigh
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
