//
//  MiddlewareBuilder.swift
//
//
//  Created by Alexander Sharko on 07.03.2024.
//

import Foundation
import UDFCore

@resultBuilder
public enum MiddlewareBuilder<State: AppReducer> {
    public static func buildBlock(_ components: MiddlewareWrapper<State>...) -> [MiddlewareWrapper<State>] {
        components.map { $0 }
    }
    
    public static func buildExpression(_ expression: some Middleware<State>) -> MiddlewareWrapper<State> {
        .init(instance: expression)
    }
    
    public static func buildExpression(_ expression: any Middleware<State>.Type) -> MiddlewareWrapper<State> {
        .init(type: expression)
    }
}

public struct MiddlewareWrapper<State: AppReducer> {
    var instance: (any Middleware<State>)?
    var type: any Middleware<State>.Type

    init(instance: any Middleware<State>) {
        self.instance = instance
        self.type = Swift.type(of: instance)
    }
    
    init(type: any Middleware<State>.Type) {
        self.instance = nil
        self.type = type
    }
}
