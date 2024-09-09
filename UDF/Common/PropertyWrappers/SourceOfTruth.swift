//
//  SourceOfTruth.swift
//  
//
//  Created by Max Kuznetsov on 12.10.2021.
//

import Foundation

@propertyWrapper
@dynamicMemberLookup
public final class SourceOfTruth<AppState: AppReducer> {
    public var wrappedValue: AppState
    private unowned var store: Optional<any Store<AppState>>

    init(wrappedValue: AppState, store: Optional<any Store<AppState>>) {
        self.wrappedValue = wrappedValue
        self.store = store
    }

    public var projectedValue: SourceOfTruth<AppState> { self }

    public subscript<C: BindableContainer, R: Reducible>(dynamicMember keyPath: WritableKeyPath<AppState, BindableReducer<C, R>>) -> BindableReducerReference<AppState, C, R> {
        BindableReducerReference(reducer: wrappedValue[keyPath: keyPath]) { [unowned store] action in
            store?.dispatch(action, priority: .userInteractive)
        }
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<AppState, R>) -> ReducerReference<AppState, R> {
        .init(reducer: wrappedValue[keyPath: keyPath]) { [unowned store] action in
            store?.dispatch(action, priority: .userInteractive)
        }
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<AppState, R>) -> ReducerScope<R> {
        ReducerScope(reducer: wrappedValue[keyPath: keyPath])
    }
}

extension SourceOfTruth: Equatable {
    public static func == (lhs: SourceOfTruth<AppState>, rhs: SourceOfTruth<AppState>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
