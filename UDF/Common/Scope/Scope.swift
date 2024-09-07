//
//  Scope.swift
//  
//
//  Created by Max Kuznetsov on 07.11.2021.
//

import Foundation

public protocol Scope: IsEquatable {}

public typealias EquatableScope = Scope & Equatable

//struct OptionalScopeWrapped<OS: Scope & Equatable>: EquatableScope {
//    let scope: OS?
//
//    static func == (lhs: OptionalScopeWrapped<OS>, rhs: some Scope) -> Bool {
//        guard let scope = lhs.scope else {
//            return true
//        }
//
//        return rhs.isEqual(scope)
//    }
//}
//
//struct EmptyScope: EquatableScope {}


@resultBuilder
public enum ScopeBuilder {

    public static func buildExpression<S: Scope & Equatable>(_ expression: S) -> some EquatableScope {
        expression
    }

    public static func buildExpression<R: Reducible>(_ expression: R) -> some EquatableScope {
        ReducerScope(reducer: expression)
    }

    public static func buildExpression<R: AppReducer>(_ expression: R) -> some EquatableScope {
        expression
    }

    public static func buildPartialBlock<S: EquatableScope>(first scope: S) -> some EquatableScope {
        scope
    }

    public static func buildPartialBlock<S1: EquatableScope, S2: EquatableScope>(accumulated: S1, next: S2) -> some EquatableScope {
        CombinedScope(accumulated, next)
    }
}

/*
@resultBuilder
public enum ScopeBuilder {

    public static func buildExpression(_ expression: Void) -> some EquatableScope {
        EmptyScope()
    }

    public static func buildExpression<S: EquatableScope>(_ expression: S?) -> some EquatableScope {
        OptionalScopeWrapped(scope: expression)
    }

    public static func buildOptional<S: EquatableScope>(_ component: S?) -> some EquatableScope {
        OptionalScopeWrapped(scope: component)
    }

    public static func buildEither<S: EquatableScope>(first component: S) -> some EquatableScope {
        component
    }

    public static func buildEither<S: EquatableScope>(second component: S) -> some EquatableScope {
        component
    }

    public static func buildPartialBlock<S: EquatableScope>(first scope: S) -> some EquatableScope {
        scope
    }

    public static func buildPartialBlock<S1: EquatableScope, S2: EquatableScope>(accumulated: S1, next: S2) -> some EquatableScope {
        CombinedScope(accumulated, next)
    }
}
*/
