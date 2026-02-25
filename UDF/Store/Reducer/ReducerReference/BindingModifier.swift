//===--- BindingModifier.swift ----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A modifier that controls how a form field binding dispatches its updates.
///
/// Use `BindingModifier` with the `bind(_:with:)` method on `ReducerReference`
/// to customize the dispatch behavior of a form field binding.
///
/// ## Examples
///
/// Apply an animation when the binding value changes:
/// ```swift
/// store.$state.someForm.bind(\.value, with: .animation(.default))
/// ```
///
/// Silence the dispatch (no logging):
/// ```swift
/// store.$state.someForm.bind(\.value, with: .silenced)
/// ```
///
/// Delay the dispatch:
/// ```swift
/// store.$state.someForm.bind(\.value, with: .delay(0.3))
/// ```
public enum BindingModifier: Sendable {
    /// Wraps the dispatched action with the specified animation.
    case animation(Animation?)

    /// Marks the dispatched action as silent, suppressing logging.
    case silenced

    /// Delays the dispatch of the action by the specified time interval.
    case delay(TimeInterval)
}
