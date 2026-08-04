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
public struct BindableReducer<ID: Hashable & Sendable, Reducer: Reducible>: Reducible {
    /// A typealias representing a dictionary of reducers associated with container IDs.
    public typealias Reducers = RCDictionary<ID, Reducer>

    /// The type of container this reducer is bound to.
    public internal(set) var containerType: Any.Type

    /// The dictionary holding the reducers associated with each container ID.
    var reducers: Reducers = .init()

    /// The wrapped value, which returns `self`.
    public var wrappedValue: BindableReducer<ID, Reducer> {
        get { self }
        set { /* do nothing */ }
    }

    /// Initializes a new `BindableReducer` with the specified reducer and container types.
    ///
    /// - Parameters:
    ///   - reducerType: The type of reducer to manage.
    ///   - bindedTo: The type of container to bind this reducer to.
    public init<C: BindableContainer>(_ reducerType: Reducer.Type, bindedTo: C.Type) where C.ID == ID {
        self.containerType = bindedTo
    }

    /// Initializes a new `BindableReducer` with a runtime container type.
    ///
    /// - Parameters:
    ///   - reducerType: The type of reducer to manage.
    ///   - containerType: The runtime type of the container to bind this reducer to.
    public init(_ reducerType: Reducer.Type, containerType: Any.Type) {
        self.containerType = containerType
    }

    /// Throws a fatal error. Use `init(reducerType:bindedTo:)` instead.
    @available(*, deprecated, message: "Use `init(reducerType:bindedTo:)` instead.")
    public init() {
        fatalError("use init(containerType:reducerType:) instead")
    }

    /// Checks for equality between two `BindableReducer` instances by comparing their reducers.
    public static func == (lhs: BindableReducer<ID, Reducer>, rhs: BindableReducer<ID, Reducer>) -> Bool {
        lhs.reducers == rhs.reducers
    }

    /// Subscript to access the reducer associated with the specified container ID.
    ///
    /// - Parameter id: The ID of the container.
    /// - Returns: The reducer associated with the given container ID, if it exists.
    public subscript(_ id: ID) -> Reducer? {
        reducers[id]
    }

    /// Subscript to access the `Scope` of the reducer associated with the specified container ID.
    ///
    /// - Parameter id: The ID of the container.
    /// - Returns: A `ReducerScope` for the associated reducer, or `nil` if no reducer is found.
    public subscript(_ id: ID) -> Scope {
        ReducerScope(reducer: reducers[id])
    }
}

// MARK: - Collection Conformance

extension BindableReducer: Collection {
    public typealias Index = Reducers.Index
    public typealias Element = (key: ID, value: Reducer)

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
        case let action as Actions._OnContainerDidLoad where action.containerType == containerType:
            guard let id = action.anyID.base as? ID else {
                return
            }
            
            reducers.retainOrCreateValue(for: id)

        case let action as Actions._OnContainerDidUnLoad where action.containerType == containerType:
            guard let id = action.anyID.base as? ID else {
                return
            }
            
            reducers.release(key: id)

        case let action as Actions._BindableAction where action.containerType == containerType:
            guard let id = action.anyID.base as? ID, var reducer = reducers[id] else {
                return
            }
            
            _ = RuntimeReducing.bindableReduce(action.value, reducer: &reducer)
            reducers.updateValue(reducer, forKey: id)
            
        default:
            break
        }
    }
}


// MARK: - AnyBindableReducer
extension BindableReducer: AnyBindableReducer {
    /// The type of container this reducer is bound to.
    var boundContainerType: any Any.Type {
        containerType
    }
    
    /// Checks if a reducer is registered for the specified container identifier.
    ///
    /// - Parameter id: The identifier of the container, expected to be of type `BindedContainer.ID`.
    /// - Returns: `true` if a reducer exists for the given identifier; otherwise, `false`.
    func hasReducer(for id: any Hashable) -> Bool {
        guard let id = id as? ID else {
            return false
        }

        return reducers.contains { $0.key == id }
    }
}
