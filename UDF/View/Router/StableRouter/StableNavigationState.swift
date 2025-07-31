//===--- StableNavigationState.swift -----------------------------------===//
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
import SwiftUI

/// A stable navigation state manager that uses Data as the source of truth to prevent container recreation.
///
/// This class provides a stable alternative to NavigationPath-based navigation by using Data serialization
/// to maintain navigation state. This prevents SwiftUI from recreating `@StateObject` instances in containers
/// when navigation changes occur.
///
/// ## Example Usage:
/// ```swift
/// @StateObject private var stableNav = StableNavigationManager()
/// 
/// NavigationStack(path: stableNav.derivedNavigationPath) {
///     // Containers here maintain stable @StateObject lifecycle
/// }
/// .environment(\.stableNavigationState, stableNav)
/// ```
public final class StableNavigationManager: ObservableObject, @unchecked Sendable {
    /// The stable data representation of the navigation stack
    @Published private var _routingData: Data = Data()
    
    /// Cached NavigationPath derived from the stable data
    @Published private var _cachedNavigationPath: NavigationPath = NavigationPath()
    
    /// Current route stack stored as AnyHashable for NavigationPath compatibility
    private var currentRoutes: [AnyHashable] = []
    
    public init() {}
    
    /// Binding to the stable routing data
    public var routingData: Binding<Data> {
        Binding(
            get: { self._routingData },
            set: { newData in
                self._routingData = newData
                self.rebuildNavigationPath()
            }
        )
    }
    
    /// Binding to the NavigationPath for SwiftUI compatibility
    public var derivedNavigationPath: Binding<NavigationPath> {
        Binding(
            get: { self._cachedNavigationPath },
            set: { _ in
                // NavigationPath is read-only in our stable system
                // All modifications should go through stable navigation methods
            }
        )
    }
    
    /// Navigate to a specific route
    public func navigate<R: StableRouting>(for routing: R.Type, to route: R.Route) where R.Route: Hashable & Codable {
        // Add route to current stack
        currentRoutes.append(route)
        
        // Update stable data
        updateStableData()
        
        // Update NavigationPath
        rebuildNavigationPath()
    }
    
    /// Navigate back one step
    public func back() {
        guard !currentRoutes.isEmpty else { return }
        currentRoutes.removeLast()
        updateStableData()
        rebuildNavigationPath()
    }
    
    /// Navigate back a specified number of steps
    public func back(steps: Int) {
        guard steps > 0, !currentRoutes.isEmpty else { return }
        let stepsToRemove = min(steps, currentRoutes.count)
        currentRoutes.removeLast(stepsToRemove)
        updateStableData()
        rebuildNavigationPath()
    }
    
    /// Navigate back to root
    public func backToRoot() {
        currentRoutes.removeAll()
        updateStableData()
        rebuildNavigationPath()
    }
    
    /// Reset navigation stack to a single route
    public func resetStack<R: StableRouting>(routing: R.Type, to route: R.Route) where R.Route: Hashable & Codable {
        currentRoutes = [route]
        updateStableData()
        rebuildNavigationPath()
    }
    
    // MARK: - Private Methods
    
    /// Update the stable data from current routes
    private func updateStableData() {
        do {
            let encoder = JSONEncoder()
            let routeData = try encoder.encode(currentRoutes.map { "\($0)" }) // Simple string representation
            _routingData = routeData
        } catch {
            print("StableNavigationManager: Failed to encode routes - \(error)")
        }
    }
    
    /// Rebuild NavigationPath from current routes
    private func rebuildNavigationPath() {
        var newPath = NavigationPath()
        for route in currentRoutes {
            newPath.append(route)
        }
        _cachedNavigationPath = newPath
    }
}

// MARK: - Environment Integration

private struct StableNavigationStateKey: EnvironmentKey {
    static let defaultValue: StableNavigationManager? = nil
}

public extension EnvironmentValues {
    /// Access to the stable navigation state from the environment
    var stableNavigationState: StableNavigationManager? {
        get { self[StableNavigationStateKey.self] }
        set { self[StableNavigationStateKey.self] = newValue }
    }
}
