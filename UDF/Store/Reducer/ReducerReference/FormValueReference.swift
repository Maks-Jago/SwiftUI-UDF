//===--- FormValueReference.swift --------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A reference that pairs a form field's key path and its containing reducer with a dispatch closure,
/// enabling both value access and chained binding creation with modifiers.
///
/// `FormValueReference` is obtained through `@dynamicMemberLookup` on a `ReducerReference`
/// when the reducer conforms to `Form`. It allows you to:
/// - Read the current value of a form field via the stored `reducer` and `keyPath`.
/// - Dispatch arbitrary actions through the associated store.
/// - Create `Binding<Value>` instances with chained dispatch modifiers (`.with(animation:)`, `.with(delay:)`, `.silent()`).
///
/// Swift disambiguates between `Binding<Value>` and `FormValueReference<Reducer, Value>` based on the
/// expected type at the call site, allowing for a seamless chaining experience.
///
/// ## Usage
///
/// ```swift
/// // Obtain a FormValueReference to a specific form field
/// let nameRef: FormValueReference<ProfileForm, String> = store.$state.profileForm.name
///
/// // Read the current value
/// let currentName = nameRef.reducer[keyPath: nameRef.keyPath]
///
/// // Dispatch actions
/// nameRef.dispatch(Actions.SubmitProfile(name: currentName))
///
/// // Create a Binding with animation
/// TextField("Name", text: store.$state.profileForm.name.with(animation: .linear))
///
/// // Create a Binding with chained modifiers
/// TextField("Search", text: store.$state.searchForm.query.with(delay: 0.3).with(animation: .default).silent())
/// ```
public struct FormValueReference<Reducer: Form, Value: Equatable & Sendable>: Sendable {
    private enum Modifier: Sendable {
        case animation(Animation?)
        case delay(TimeInterval)
        case silent
    }

    /// The key path to the form field within the reducer.
    private let keyPath: WritableKeyPath<Reducer, Value>

    /// The reducer instance that contains the form field.
    private let reducer: Reducer

    /// A closure that handles the dispatching of actions.
    private let dispatcher: @Sendable (any Action) -> Void

    /// An array of modifiers to apply to the dispatched action.
    private let modifiers: [Modifier]

    /// Initializes a new `FormValueReference` with the specified key path, reducer, and dispatcher.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the form field within the reducer.
    ///   - reducer: The reducer instance that contains the form field.
    ///   - dispatcher: A closure to handle action dispatching.
    init(
        keyPath: WritableKeyPath<Reducer, Value>,
        reducer: Reducer,
        dispatcher: @escaping @Sendable (any Action) -> Void
    ) {
        self.init(keyPath: keyPath, reducer: reducer, dispatcher: dispatcher, modifiers: [])
    }

    /// Internal initializer for creating a reference with accumulated modifiers.
    private init(
        keyPath: WritableKeyPath<Reducer, Value>,
        reducer: Reducer,
        dispatcher: @escaping @Sendable (any Action) -> Void,
        modifiers: [Modifier]
    ) {
        self.keyPath = keyPath
        self.reducer = reducer
        self.dispatcher = dispatcher
        self.modifiers = modifiers
    }

    /// Dispatches an action through the associated store.
    ///
    /// - Parameter action: The action to dispatch.
    private func dispatch(_ action: some Action) {
        dispatcher(action)
    }

    // MARK: - Chained Modifiers

    /// Adds an animation modifier to the reference.
    ///
    /// - Parameter animation: The animation to apply to the dispatched update action.
    /// - Returns: A new `FormValueReference` with the animation modifier appended.
    public func with(animation: Animation?) -> Self {
        appended(modifier: .animation(animation))
    }

    /// Adds a delay modifier to the reference.
    ///
    /// - Parameter interval: The time interval to delay the dispatch.
    /// - Returns: A new `FormValueReference` with the delay modifier appended.
    public func with(delay interval: TimeInterval) -> Self {
        appended(modifier: .delay(interval))
    }

    /// Adds a silent modifier to the reference, suppressing action logging.
    ///
    /// - Returns: A new `FormValueReference` with the silent modifier appended.
    public func silent() -> Self {
        appended(modifier: .silent)
    }

    // MARK: - Binding Conversion

    /// Creates a `Binding` with the specified animation applied to the dispatched update action.
    ///
    /// - Parameter animation: The animation to apply when the binding value changes.
    /// - Returns: A `Binding` whose setter dispatches the update action with all accumulated modifiers and the new animation.
    public func with(animation: Animation?) -> Binding<Value> {
        with(animation: animation).asBinding()
    }

    /// Creates a `Binding` with the specified delay applied to the dispatched update action.
    ///
    /// - Parameter interval: The time interval to delay the dispatch.
    /// - Returns: A `Binding` whose setter dispatches the update action with all accumulated modifiers and the new delay.
    public func with(delay interval: TimeInterval) -> Binding<Value> {
        with(delay: interval).asBinding()
    }

    /// Creates a `Binding` whose dispatched update action is silenced (suppresses logging).
    ///
    /// - Returns: A `Binding` whose setter dispatches the update action with all accumulated modifiers and the silent modifier.
    public func silent() -> Binding<Value> {
        silent().asBinding()
    }

    // MARK: - Private Helpers

    /// Returns a new reference with the specified modifier appended to the current list.
    private func appended(modifier: Modifier) -> Self {
        .init(keyPath: keyPath, reducer: reducer, dispatcher: dispatcher, modifiers: modifiers + [modifier])
    }

    /// Converts the reference and its accumulated modifiers into a SwiftUI `Binding`.
    private func asBinding() -> Binding<Value> {
        Binding {
            self.reducer[keyPath: self.keyPath]
        } set: { value in
            let baseAction = Actions.UpdateFormField(keyPath: self.keyPath, value: value)
            let modifiedAction = self.modifiers.reduce(baseAction as any Action) { action, modifier in
                switch modifier {
                case .animation(let anim): return action.with(animation: anim)
                case .delay(let interval): return action.with(delay: interval)
                case .silent: return action.silent()
                }
            }
            self.dispatcher(modifiedAction)
        }
    }
}
