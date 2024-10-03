//===--- CancellableTask.swift ------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine

/// A protocol that represents a cancellable task.
///
/// `CancellableTask` provides a common interface for tasks that can be canceled. It is useful when working with asynchronous operations
/// that need to be explicitly canceled, such as network requests or long-running tasks.
public protocol CancellableTask {
    /// Cancels the task.
    func cancel()
}

// MARK: - Conformance to CancellableTask

/// Extends `AnyCancellable` to conform to `CancellableTask`.
///
/// This allows `AnyCancellable` instances, typically used in Combine, to be handled using the `CancellableTask` interface.
extension AnyCancellable: CancellableTask {}

/// Extends `Task` (with `Void` output and `Never` failure) to conform to `CancellableTask`.
///
/// This allows Swift's structured concurrency tasks to be handled using the `CancellableTask` interface, providing a unified way
/// to manage task cancellation.
extension Task<Void, Never>: CancellableTask {}
