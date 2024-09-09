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

//    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<AppState, R>) -> ReducerScope<R> {
//        ReducerScope(reducer: wrappedValue[keyPath: keyPath])
//    }
}

extension SourceOfTruth: Equatable {
    public static func == (lhs: SourceOfTruth<AppState>, rhs: SourceOfTruth<AppState>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}


/*
import SwiftUI

public final class BindableReducerReference<AppState: AppReducer, BindedContainer: BindableContainer, Reducer: Reducible> {
    private var reducer: BindableReducer<BindedContainer, Reducer>
    private unowned var store: Optional<any Store<AppState>>

//    public var projectedValue: Reducer {
//        get { self.reducer }
//        set { self.reducer = newValue }
//    }

    init(reducer: BindableReducer<BindedContainer, Reducer>, store: Optional<any Store<AppState>>) {
        self.reducer = reducer
        self.store = store
    }

//    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerReference<AppState, R> {
//        .init(reducer: reducer[keyPath: keyPath], store: store)
//    }

//    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerScope<R> {
//        reducer[id]
//    }

    public subscript(_ id: BindedContainer.ID) -> Reducer? {
        reducer[id]
    }

    public subscript<T: Equatable>(keyPath: WritableKeyPath<Reducer, T>, id: BindedContainer.ID) -> Binding<T?> where Reducer: Form {
        Binding(
            get: { self.reducer[id]?[keyPath: keyPath] },
            set: { [store] value in
                if let value {
                    store?.dispatch(
                        Actions.UpdateFormField(keyPath: keyPath, value: value)
                            .bindable(containerType: BindedContainer.self, id: id),
                        priority: .userInteractive
                    )
                }
            }
        )
//        reducer[id]
    }

//    public subscript<T>(_ id: BindedContainer.ID, defaultValue: T) -> Binding<T>? {
//        reducer[id]
//    }
}

//extension BindableReducerReference where Reducer: Form {
//
//    public subscript<T: Equatable>(dynamicMember keyPath: WritableKeyPath<Reducer, T>) -> Binding<T> {
//        Binding(
//            get: { self.reducer[keyPath: keyPath] },
//            set: { [store] value in
//                store?.dispatch(
//                    Actions.UpdateFormField(keyPath: keyPath, value: value)
//                        .bindable(containerType: BindedContainer.self, id: <#T##Hashable#>),
//                    priority: .userInteractive
//                )
//            }
//        )
//    }
//}
*/
