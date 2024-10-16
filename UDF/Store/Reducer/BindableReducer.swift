//===--- BindableReducer.swift ------------------------------------===//
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

/// A property wrapper that manages a collection of reducers bound to a specific container type.
///
/// `BindableReducer` is designed to automatically manage multiple instances of reducers associated with different instances
/// of a `BindableContainer`. It allows actions to be dispatched and reduced in a dynamic, container-bound manner, facilitating
/// the organization of complex state management in a SwiftUI application.
@propertyWrapper
public struct BindableReducer<BindedContainer: BindableContainer, Reducer: Reducible>: Reducible {
    /// A typealias representing a dictionary of reducers associated with container IDs.
    public typealias Reducers = RCDictionary<BindedContainer.ID, Reducer>

    /// The type of container this reducer is bound to.
    public internal(set) var containerType: BindedContainer.Type

    /// The dictionary holding the reducers associated with each container ID.
    var reducers: Reducers = .init()

    /// The wrapped value, which returns `self`.
    public var wrappedValue: BindableReducer<BindedContainer, Reducer> {
        get { self }
        set { /* do nothing */ }
    }

    /// Initializes a new `BindableReducer` with the specified reducer and container types.
    ///
    /// - Parameters:
    ///   - reducerType: The type of reducer to manage.
    ///   - bindedTo: The type of container to bind this reducer to.
    public init(_ reducerType: Reducer.Type, bindedTo: BindedContainer.Type) {
        self.containerType = bindedTo
    }

    /// Throws a fatal error. Use `init(reducerType:bindedTo:)` instead.
    @available(*, deprecated, message: "Use `init(reducerType:bindedTo:)` instead.")
    public init() {
        fatalError("use init(containerType:reducerType:) instead")
    }

    /// Checks for equality between two `BindableReducer` instances by comparing their reducers.
    public static func == (lhs: BindableReducer<BindedContainer, Reducer>, rhs: BindableReducer<BindedContainer, Reducer>) -> Bool {
        lhs.reducers == rhs.reducers
    }

    /// Subscript to access the reducer associated with the specified container ID.
    ///
    /// - Parameter id: The ID of the container.
    /// - Returns: The reducer associated with the given container ID, if it exists.
    public subscript(_ id: BindedContainer.ID) -> Reducer? {
        reducers[id]
    }

    /// Subscript to access the `Scope` of the reducer associated with the specified container ID.
    ///
    /// - Parameter id: The ID of the container.
    /// - Returns: A `ReducerScope` for the associated reducer, or `nil` if no reducer is found.
    public subscript(_ id: BindedContainer.ID) -> Scope {
        ReducerScope(reducer: reducers[id])
    }
}

// MARK: - Collection Conformance

extension BindableReducer: Collection {
    public typealias Index = Reducers.Index
    public typealias Element = (key: BindedContainer.ID, value: Reducer)

    /// The starting index of the collection, used in iterations.
    public var startIndex: Index { reducers.startIndex }

    /// The ending index of the collection, used in iterations.
    public var endIndex: Index { reducers.endIndex }

    /// Required subscript to access an element of the collection at the specified index.
    ///
    /// - Parameter index: The position in the collection.
    /// - Returns: The element at the specified index.
    public subscript(index: Index) -> Element {
        let element = reducers[index]
        return (element.key, element.value)
    }

    /// Returns the next index in the collection.
    ///
    /// - Parameter i: The current index.
    /// - Returns: The index immediately after the given index.
    public func index(after i: Index) -> Index {
        reducers.index(after: i)
    }
}

// MARK: - Runtime Reducing

public extension BindableReducer {
    /// Reduces an action by managing its effects on the collection of bound reducers.
    ///
    /// This method handles specific actions to manage the lifecycle of reducers (`_OnContainerDidLoad`, `_OnContainerDidUnLoad`, and
    /// `_BindableAction`),
    /// adding, removing, or reducing the appropriate reducers based on the action's type.
    ///
    /// - Parameter action: The action to be reduced.
    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions._OnContainerDidLoad<BindedContainer>:
            reducers.retainOrCreateValue(for: action.id)

        case let action as Actions._OnContainerDidUnLoad<BindedContainer>:
            reducers.release(key: action.id)

        case let action as Actions._BindableAction<BindedContainer>:
            for (key, var reducer) in reducers where key == action.id {
                _ = RuntimeReducing.bindableReduce(action.value, reducer: &reducer)
                reducers.updateValue(reducer, forKey: key)
            }

        default:
            break
        }
    }
}

public struct RCDictionary<Key: Hashable, Value: Initable & Equatable>: Equatable {
    private var keyValues: [Key: ReducerBox] = [:]

    mutating func retainOrCreateValue(for key: Key) {
        if keyValues[key] != nil {
            keyValues[key]?.retain()
        } else {
            keyValues[key] = .init(value: .init())
        }
    }

    mutating func release(key: Key) {
        if keyValues[key]?.release() == true {
            keyValues.removeValue(forKey: key)
        }
    }

    mutating func updateValue(_ value: Value, forKey key: Key) {
        var box = keyValues[key] ?? .init(value: value)
        box.value = value
        keyValues[key] = box
    }

    public subscript(_ key: Key) -> Value? {
        keyValues[key]?.value
    }
}

// MARK: - ReducerBox
public extension RCDictionary {
    struct ReducerBox: Equatable {
        var value: Value
        private var referenceCount: Int = 1

        init(value: Value) {
            self.value = value
        }

        mutating func retain() {
            referenceCount += 1
        }

        mutating func release() -> Bool {
            referenceCount -= 1
            return referenceCount <= 0
        }
    }
}

// MARK: - Collection
extension RCDictionary: Collection {
    public typealias Index = [Key: ReducerBox].Index
    public typealias Element = (key: Key, value: Value)

    /// The starting index of the collection, used in iterations.
    public var startIndex: Index { keyValues.startIndex }

    /// The ending index of the collection, used in iterations.
    public var endIndex: Index { keyValues.endIndex }

    /// Required subscript to access an element of the collection at the specified index.
    ///
    /// - Parameter index: The position in the collection.
    /// - Returns: The element at the specified index.
    public subscript(index: Index) -> Element {
        let element = keyValues[index]
        return (element.key, element.value.value)
    }

    /// Returns the next index in the collection.
    ///
    /// - Parameter i: The current index.
    /// - Returns: The index immediately after the given index.
    public func index(after i: Index) -> Index {
        keyValues.index(after: i)
    }
}
