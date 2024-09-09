//
//  ReducerReference.swift
//  
//
//  Created by Max Kuznetsov on 13.09.2021.
//

import Foundation
import SwiftUI

public protocol ReducerReferincing<AppState, Reducer>: AnyObject {
    associatedtype AppState: AppReducer
    associatedtype Reducer: Reducible
    associatedtype ProjectedValue

    var projectedValue: ProjectedValue { get set }
}

@dynamicMemberLookup
public class ReducerReference<AppState: AppReducer, Reducer: Reducible> {
    private(set) var reducer: Reducer

    var dispatcher: (any Action) -> Void

    public var wrappedValue: Reducer { reducer }
    public var projectedValue: ReducerReference {
        get { self.reducer }
        set { self.reducer = newValue }
    }

    init(reducer: Reducer, dispatcher: @escaping (any Action) -> Void) {
        self.reducer = reducer
        self.dispatcher = dispatcher
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerReference<AppState, R> {
        .init(reducer: reducer[keyPath: keyPath], dispatcher: dispatcher)
    }

    public subscript<C: BindableContainer, R: Reducible>(dynamicMember keyPath: WritableKeyPath<Reducer, BindableReducer<C, R>>) -> BindableReducerReference<AppState, C, R> {
        BindableReducerReference(reducer: reducer[keyPath: keyPath], dispatcher: dispatcher)
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerScope<R> {
        ReducerScope(reducer: reducer[keyPath: keyPath])
    }
}

extension ReducerReference where Reducer: Form {

    public subscript<T: Equatable>(dynamicMember keyPath: WritableKeyPath<Reducer, T>) -> Binding<T> {
        Binding(
            get: { self.reducer[keyPath: keyPath] },
            set: { value in
                self.dispatcher(Actions.UpdateFormField(keyPath: keyPath, value: value))
            }
        )
    }
}


public final class BindableReducerReference<AppState: AppReducer, BindedContainer: BindableContainer, Reducer: Reducible>: ReducerReference<AppState, BindableReducer<BindedContainer, Reducer>> {

    var bindableId: BindedContainer.ID? = nil

    override init(reducer: BindableReducer<BindedContainer, Reducer>, dispatcher: @escaping (any Action) -> Void) {
        super.init(reducer: reducer, dispatcher: dispatcher)

        self.dispatcher = { [weak self] action in
            if let bindableId = self?.bindableId {
                dispatcher(action.bindable(containerType: BindedContainer.self, id: bindableId))
            } else {
                dispatcher(action)
            }
        }
    }

//    init(reducer: Reducer) {
//        self.reducer = reducer
//        self.dispatcher = { [unowned store] action in
//            store?.dispatch(action, priority: .userInteractive)
//        }
//    }

//    private var reducer: BindableReducer<BindedContainer, Reducer>

    //    public var projectedValue: Reducer {
    //        get { self.reducer }
    //        set { self.reducer = newValue }
    //    }

//    init(reducer: BindableReducer<BindedContainer, Reducer>, store: Optional<any Store<AppState>>) {
//        self.reducer = reducer
//        self.store = store
//    }

    //    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerReference<AppState, R> {
    //        .init(reducer: reducer[keyPath: keyPath], store: store)
    //    }

    //    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerScope<R> {
    //        reducer[id]
    //    }

    public subscript(id: BindedContainer.ID) -> ReducerReference<AppState, Reducer> {
        self.bindableId = id
        return ReducerReference(reducer: reducer[id]!, dispatcher: dispatcher)

//        reducer[id]
    }
//
//    public subscript<T: Equatable>(keyPath: WritableKeyPath<Reducer, T>, id: BindedContainer.ID) -> Binding<T?> where Reducer: Form {
//        Binding(
//            get: { self.reducer[id]?[keyPath: keyPath] },
//            set: { [store] value in
//                if let value {
//                    store?.dispatch(
//                        Actions.UpdateFormField(keyPath: keyPath, value: value)
//                            .bindable(containerType: BindedContainer.self, id: id),
//                        priority: .userInteractive
//                    )
//                }
//            }
//        )
//    }

    //    public subscript<T>(_ id: BindedContainer.ID, defaultValue: T) -> Binding<T>? {
    //        reducer[id]
    //    }
}
