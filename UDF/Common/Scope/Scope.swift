//
//  Scope.swift
//  
//
//  Created by Max Kuznetsov on 07.11.2021.
//

import Foundation

public protocol Scope: IsEquatable {}

public typealias EquatableScope = Scope & Equatable

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
