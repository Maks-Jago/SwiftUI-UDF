//
//  AppReducer+Runtime.swift
//  
//
//  Created by Max Kuznetsov on 30.08.2021.
//

import Foundation
import Runtime

enum RuntimeReducing {
    static func initialSetup<R: AppReducer>(reducer rootReducer: inout R) {
        guard let info = try? typeInfo(of: R.self) else {
            return
        }

        for property in info.properties {
            guard let reducer = try? property.get(from: rootReducer) as? Reducing else {
                continue
            }

            var mutableReducer = tryToCallInitialSetup(reducer, rootReducer: rootReducer)

            initialSetup(reducer: &mutableReducer, nestedReducerType: property.type, rootReducer: rootReducer)
            try? property.set(value: mutableReducer, on: &rootReducer)
        }
    }

    private static func tryToCallInitialSetup<R: AppReducer>(_ reducer: Reducing, rootReducer: R) -> Reducing {
        func callInitialSetup<R2: AppReducer, I: InitialSetup>(_ reducer: I, rootReducer: R2) -> Reducing {
            var mutableReducer = reducer
            mutableReducer.initialSetup(with: rootReducer as! I.AppState)
            return mutableReducer
        }

        var mutableReducer = reducer
        if let initialSetup = mutableReducer as? any InitialSetup {
            mutableReducer = callInitialSetup(initialSetup, rootReducer: rootReducer)
        }

        return mutableReducer
    }


    private static func initialSetup<R: AppReducer>(reducer: inout Reducing, nestedReducerType: Any.Type, rootReducer: R) {
        guard let info = try? typeInfo(of: nestedReducerType) else {
            return
        }

        for property in info.properties {
            if var mutableReducer = try? property.get(from: reducer) as? Reducing {
                mutableReducer = tryToCallInitialSetup(mutableReducer, rootReducer: rootReducer)

                initialSetup(reducer: &mutableReducer, nestedReducerType: property.type, rootReducer: rootReducer)
                try? property.set(value: mutableReducer, on: &reducer)
            }
        }
    }


    static func reduce<R>(_ action: some Action, reducer rootReducer: inout R) -> Bool {
        guard let info = try? typeInfo(of: R.self) else {
            return false
        }

        var mutaded = false

        for property in info.properties {
            guard let reducer = try? property.get(from: rootReducer) as? Reducing else {
                continue
            }

            var mutableReducer = reducer
            mutableReducer.reduce(action)

            if var formable = mutableReducer as? any Form {
                formable.reduceBasicFormFields(action)
                mutableReducer = formable
            }

            if reduce(action, reducer: &mutableReducer, type: property.type) {
                mutaded = true
            }

            if !mutableReducer.isEqual(reducer) {
                try? property.set(value: mutableReducer, on: &rootReducer)
                mutaded = true
            }
        }

        return mutaded
    }

    static func reduce(_ action: some Action, reducer: inout Reducing, type: Any.Type) -> Bool {
        guard let info = try? typeInfo(of: type) else {
            return false
        }
        var mutaded = false

        for property in info.properties {
            if var nestedReducer = try? property.get(from: reducer) as? Reducing {
                if reduce(action, reducer: &nestedReducer, type: property.type) {
                    if var wrapper = reducer as? WrappedReducer {
                        wrapper.reducer = nestedReducer
                    } else {
                        try? property.set(value: nestedReducer, on: &reducer)
                    }
                    mutaded = true
                }

                var mutableReducer = nestedReducer
                mutableReducer.reduce(action)

                if var formable = mutableReducer as? any Form {
                    formable.reduceBasicFormFields(action)
                    mutableReducer = formable
                }

                if !mutableReducer.isEqual(nestedReducer) {
                    try? property.set(value: mutableReducer, on: &reducer)
                    mutaded = true
                }
            }
        }

        return mutaded
    }
}

extension Mergeable {
    public func filled(from value: Self, mutate: (_ filledValue: inout Self, _ oldValue: Self) -> Void) -> Self {
        var mutableSelf = self
        do {
            let info = try typeInfo(of: Self.self)

            for property in info.properties {
                let newValue = try property.get(from: value)
                try property.set(value: newValue, on: &mutableSelf)
            }

        } catch {
            return value
        }

        mutate(&mutableSelf, self)
        return mutableSelf
    }
}
