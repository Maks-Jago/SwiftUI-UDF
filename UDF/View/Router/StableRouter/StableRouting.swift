//===--- StableRouting.swift -------------------------------------------===//
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

/// A protocol that extends `Routing` to support stable navigation through Data serialization.
///
/// `StableRouting` requires routes to be `Codable` to enable stable navigation state management.
/// This prevents container recreation issues by using Data as the source of truth for navigation state.
///
/// ## Requirements:
/// - Routes must be `Hashable` and `Codable`
/// - Must provide serialization methods for route stacks
///
/// ## Example:
/// ```swift
/// struct ExampleRouting: StableRouting {
///     enum Route: Hashable, Codable {
///         case details(String)
///         case settings
///     }
///
///     @ViewBuilder
///     func view(for route: Route) -> some View {
///         switch route {
///         case .details(let id):
///             DetailsView(id: id)
///         case .settings:
///             SettingsView()
///         }
///     }
///
///     static func encodeRouteStack(_ routes: [Route]) -> Data {
///         return (try? JSONEncoder().encode(routes)) ?? Data()
///     }
///
///     static func decodeRouteStack(from data: Data) -> [Route] {
///         return (try? JSONDecoder().decode([Route].self, from: data)) ?? []
///     }
/// }
/// ```
public protocol StableRouting: Routing where Route: Hashable & Codable {
    /// Encode a route stack to Data for stable storage
    ///
    /// - Parameter routes: The array of routes to encode
    /// - Returns: Data representation of the route stack
    static func encodeRouteStack(_ routes: [Route]) -> Data
    
    /// Decode a route stack from Data
    ///
    /// - Parameter data: The data to decode routes from
    /// - Returns: Array of decoded routes, or empty array if decoding fails
    static func decodeRouteStack(from data: Data) -> [Route]
}

/// Default implementations for common serialization patterns
public extension StableRouting {
    /// Default JSON encoding implementation
    static func encodeRouteStack(_ routes: [Route]) -> Data {
        do {
            return try JSONEncoder().encode(routes)
        } catch {
            print("StableRouting: Failed to encode routes - \(error)")
            return Data()
        }
    }
    
    /// Default JSON decoding implementation
    static func decodeRouteStack(from data: Data) -> [Route] {
        guard !data.isEmpty else { return [] }
        
        do {
            return try JSONDecoder().decode([Route].self, from: data)
        } catch {
            print("StableRouting: Failed to decode routes - \(error)")
            return []
        }
    }
}