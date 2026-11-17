//===--- Mergeable.swift -------------------------------------===//
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

/// A type that defines how a new value and the old value stored for the same identity combine into one.
///
/// A server often describes one entity at different levels of detail. A list endpoint can return a summary
/// of a customer, while a detail endpoint returns the complete customer. When both responses are written to
/// the same storage, replacing the stored value lets the most recent response discard properties that only
/// the other response provides. A `Mergeable` type decides, property by property, which value is kept.
///
/// Implement ``merging(new:old:)`` to describe the merge. The new value is the value being stored, and the
/// old value is the value already stored. Declare the properties that a summary can omit as optional, start
/// from the new value, and use ``keeping(_:from:where:)`` to restore the properties of the old value that
/// the new value lacks:
///
/// ```swift
/// struct Customer: StorageItem {
///     struct ID: Hashable, Sendable {
///         var value: Int
///     }
///
///     var id: ID
///     var name: String
///     var biography: String?
///     var subscriberCount: Int?
///     var interests: [String]?
///
///     static let empty = Customer(
///         id: ID(value: -1),
///         name: "",
///         biography: nil,
///         subscriberCount: nil,
///         interests: nil
///     )
/// }
///
/// extension Customer: Mergeable {
///     static func merging(new newValue: Customer, old oldValue: Customer) -> Customer {
///         newValue
///             .keeping(\.biography, from: oldValue, where: newValue.biography == nil)
///             .keeping(\.subscriberCount, from: oldValue, where: newValue.subscriberCount == nil)
///             .keeping(\.interests, from: oldValue, where: newValue.interests == nil)
///     }
/// }
/// ```
///
/// ## Merging in storage
///
/// UDF calls ``merging(new:old:)`` when it stores a value under a key that already holds one:
///
/// - `insert(item:)` and `insert(items:)` on `Dictionary` and `OrderedDictionary`, when `Value` is both
///   `Identifiable` and `Mergeable` and `Key` is `Value.ID`. Items passed to one `insert(items:)` call are
///   merged in order.
/// - Assigning a non-optional `Value` through `dictionary[key]` on `Dictionary` and `OrderedDictionary`,
///   when `Value` is `Mergeable`.
///
/// When the key holds no value, the new value is stored unchanged and ``merging(new:old:)`` isn't called.
///
/// A ``Storage`` gets merging by inserting through these operations:
///
/// ```swift
/// struct AllCustomers: Storage {
///     var byId: [Customer.ID: Customer] = [:]
///
///     mutating func reduce(_ action: some Action) {
///         switch action {
///         case let action as Actions.DidLoadItems<Customer>:
///             byId.insert(items: action.items)
///
///         case let action as Actions.DidLoadItem<Customer>:
///             byId.insert(item: action.item)
///
///         default:
///             break
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Merging Values
///
/// - ``merging(new:old:)``
///
/// ### Keeping Properties
///
/// - ``keeping(_:from:where:)``
public protocol Mergeable {
    /// Returns the value to store when a new value replaces an old value for the same identity.
    ///
    /// Write the merge as a single expression that starts from `newValue` and applies one
    /// ``Mergeable/keeping(_:from:where:)`` call for each property whose old value must survive. A property
    /// without a `keeping` call takes the value from `newValue`.
    ///
    /// ```swift
    /// static func merging(new newValue: Customer, old oldValue: Customer) -> Customer {
    ///     newValue
    ///         .keeping(\.biography, from: oldValue, where: newValue.biography == nil)
    ///         .keeping(\.subscriberCount, from: oldValue, where: newValue.subscriberCount == nil)
    ///         .keeping(\.interests, from: oldValue, where: newValue.interests == nil)
    /// }
    /// ```
    ///
    /// Each line reads as "keep the old property when the new value doesn't include it". An optional
    /// property expresses that directly: `nil` means the response omitted the property, so any value the
    /// response does include, such as zero or an empty array, replaces the old one.
    ///
    /// When a non-optional property arrives with a placeholder in place of a missing value, the condition
    /// tests for that placeholder. The placeholder then never replaces the old value, even when the server
    /// sends it as the actual value:
    ///
    /// ```swift
    /// newValue
    ///     .keeping(\.name, from: oldValue, where: newValue.name.isEmpty)
    /// ```
    ///
    /// A condition can inspect any property of `newValue` and `oldValue`. In this example, a missing
    /// biography identifies a summary response, so the old interests are kept as well:
    ///
    /// ```swift
    /// static func merging(new newValue: Customer, old oldValue: Customer) -> Customer {
    ///     newValue
    ///         .keeping(\.biography, from: oldValue, where: newValue.biography == nil)
    ///         .keeping(\.interests, from: oldValue, where: newValue.biography == nil)
    /// }
    /// ```
    ///
    /// Conditions read only `newValue` and `oldValue`, so the lines are independent of one another and
    /// their order doesn't change the result, provided each line names a different property.
    ///
    /// The `keeping` method selects the new or the old value of a property as a whole; it doesn't combine
    /// the two. A key path through a nested value, such as `\.address.city`, selects an individual property
    /// of that value. The elements of two collections aren't combined.
    ///
    /// - Parameters:
    ///   - newValue: The value being stored.
    ///   - oldValue: The value already stored for the same identity.
    /// - Returns: The value to store.
    static func merging(new newValue: Self, old oldValue: Self) -> Self
}
