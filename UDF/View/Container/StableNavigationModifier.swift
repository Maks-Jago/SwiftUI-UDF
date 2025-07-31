//===--- StableNavigationModifier.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A view modifier that automatically provides stable navigation support to prevent container recreation.
///
/// This modifier creates a `StableNavigationManager` and injects it into the environment,
/// allowing containers to benefit from stable navigation without manual setup.
///
/// ## Usage:
/// ```swift
/// MyContainer()
///     .withStableNavigation()
/// ```
///
/// Or for conditional stable navigation:
/// ```swift
/// MyContainer()
///     .withStableNavigation(enabled: shouldUseStableNav)
/// ```
private struct StableNavigationModifier: ViewModifier {
    let enabled: Bool
    @StateObject private var stableNavigation = StableNavigationManager()
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .environment(\.stableNavigationState, stableNavigation)
        } else {
            content
        }
    }
}

public extension View {
    /// Adds automatic stable navigation support to prevent container recreation issues.
    ///
    /// This modifier creates a `StableNavigationManager` and provides it through the environment.
    /// Containers that experience recreation issues during navigation can benefit from this.
    ///
    /// - Parameter enabled: Whether to enable stable navigation. Defaults to `true`.
    /// - Returns: A view with stable navigation support.
    func withStableNavigation(enabled: Bool = true) -> some View {
        modifier(StableNavigationModifier(enabled: enabled))
    }
}