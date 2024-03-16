//
//  MiddlewareBuilder.swift
//
//
//  Created by Alexander Sharko on 07.03.2024.
//

import Foundation
import UDFCore

@available(iOS 16.0.0, macOS 13.0.0, *)
@resultBuilder
enum MiddlewareBuilder<State: AppReducer> {
    static func buildBlock(_ components: MiddlewareWrapper<State>...) -> [MiddlewareWrapper<State>] {
        components.map { $0 }
    }
    
    static func buildExpression(_ expression: some Middleware<State>) -> MiddlewareWrapper<State> {
        .init(instance: expression)
    }
    
    static func buildExpression(_ expression: any Middleware<State>.Type) -> MiddlewareWrapper<State> {
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
