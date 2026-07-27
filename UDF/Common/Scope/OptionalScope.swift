//===--- OptionalScope.swift ---------------------------------------===//
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

/// A `Scope` that wraps the result of an `if`/`if let` branch without a matching `else`
/// inside a `@ScopeBuilder` block.
///
/// When the condition is `false` (or the optional being bound is `nil`), `wrapped` is `nil`
/// and `OptionalScope` behaves like `NoneScope`: it is always equal to another empty
/// `OptionalScope`, meaning it never contributes to change detection when the branch isn't taken.
///
/// ## Example
/// ```swift
/// @ScopeBuilder
/// func scope(for state: AppState) -> Scope {
///     if let bookToModalPresent = state.rootForm.bookToModalPresent {
///         state.allBooks.bookBy(id: bookToModalPresent)
///     }
/// }
/// ```
public struct OptionalScope<Wrapped: EquatableScope>: EquatableScope {
    /// The scope produced by the taken branch, or `nil` if the branch wasn't taken.
    let wrapped: Wrapped?

    init(_ wrapped: Wrapped?) {
        self.wrapped = wrapped
    }

    public static func == (lhs: OptionalScope<Wrapped>, rhs: OptionalScope<Wrapped>) -> Bool {
        lhs.wrapped == rhs.wrapped
    }
}
