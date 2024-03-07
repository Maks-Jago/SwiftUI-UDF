//
//  MiddlewareBuilder.swift
//
//
//  Created by Alexander Sharko on 07.03.2024.
//

import Foundation

@available(iOS 16.0.0, macOS 13.0.0, *)
@resultBuilder
struct MiddlewareBuilder {
    static func buildBlock<State: AppReducer>(_ components: MiddlewareWrapper<State>...) -> [MiddlewareWrapper<State>] {
        components.map { $0 }
    }
    
    static func buildExpression<State: AppReducer>(_ expression: some Middleware<State>) -> MiddlewareWrapper<State> {
        .init(instance: expression)
    }
    
    static func buildExpression<State: AppReducer>(_ expression: any Middleware<State>.Type) -> MiddlewareWrapper<State> {
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


@available(iOS 16.0.0, macOS 13.0.0, *)
func test() async {
    let store = try! EnvironmentStore(initial: AppState(), loggers: [.consoleDebug])

    await store.subscribeAsync { store in
        Middleware1.self
        Middleware2.self
        Middleware2(store: store)
        Middleware3(store: store)
    }
}

class Middleware1: BaseReducibleMiddleware<AppState> {
    var environment: Void!
    
    func reduce(_ action: some Action, for state: State) {
        switch action {
        default: break
        }
    }
}

class Middleware2: BaseReducibleMiddleware<AppState> {
    var environment: Void!
    
    func reduce(_ action: some Action, for state: State) {
        switch action {
        default: break
        }
    }
}

class Middleware3: BaseReducibleMiddleware<AppState> {
    var environment: Void!
    
    func reduce(_ action: some Action, for state: State) {
        switch action {
        default: break
        }
    }
}

struct AppState: AppReducer {}
