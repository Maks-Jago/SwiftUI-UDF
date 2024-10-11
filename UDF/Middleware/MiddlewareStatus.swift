//===--- MiddlewareStatus.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// An enumeration that represents the status of a middleware in the UDF architecture.
///
/// `MiddlewareStatus` indicates whether a middleware is actively processing actions or is in a suspended state.
/// This status can be used to control the middleware's behavior, such as pausing certain operations when the middleware is not needed.
///
/// ## Cases
/// - `active`: Indicates that the middleware is currently active and processing actions.
/// - `suspend`: Indicates that the middleware is temporarily suspended and not processing actions.
///             All executing or running effects will be automatically canceled
///
/// ## Example Usage
/// ```swift
/// func status(for state: MyAppState) -> MiddlewareStatus {
///     state.isUserLoggedIn ? .active : .suspend
/// }
/// ```
public enum MiddlewareStatus: Sendable {
    /// Middleware is active and processing actions.
    case active

    /// Middleware is suspended and not processing actions.
    case suspend
}
