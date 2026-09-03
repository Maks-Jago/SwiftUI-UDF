//===--- EitherScope.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A `Scope` that wraps the result of an `if`/`else` (or `switch`) branch inside a `@ScopeBuilder`
/// block, mirroring how `_ConditionalContent` lets `ViewBuilder` support branching.
///
/// Two `EitherScope` values are only equal when they resolved to the same branch and the
/// wrapped scopes are equal; switching branches is always treated as a change.
///
/// ## Example
/// ```swift
/// @ScopeBuilder
/// func scope(for state: AppState) -> Scope {
///     if let bookToModalPresent = state.rootForm.bookToModalPresent {
///         state.allBooks.bookBy(id: bookToModalPresent)
///     } else {
///         .none
///     }
/// }
/// ```
public enum EitherScope<First: EquatableScope, Second: EquatableScope>: EquatableScope {
    /// The scope produced when the condition evaluated to `true`.
    case first(First)

    /// The scope produced when the condition evaluated to `false`.
    case second(Second)

    public static func == (lhs: EitherScope<First, Second>, rhs: EitherScope<First, Second>) -> Bool {
        switch (lhs, rhs) {
        case let (.first(lhsScope), .first(rhsScope)):
            return lhsScope == rhsScope

        case let (.second(lhsScope), .second(rhsScope)):
            return lhsScope == rhsScope

        default:
            return false
        }
    }
}
