//
//  TestStore.swift
//
//
//  Created by Max Kuznetsov on 05.10.2021.
//

import Combine
import SwiftUI
import Testing

@globalActor public actor TestStoreActor {
    public static let shared = TestStoreActor()
}

@TestStoreActor
public final class TestStore<State: AppReducer> {
    private struct TestStoreLogger: ActionLogger {
        var actionFilters: [ActionFilter] = [VerboseActionFilter()]
        var actionDescriptor: ActionDescriptor = StringDescribingActionDescriptor()

        func log(_ action: LoggingAction, description: String) {
            print("Reduce\t\t", description)
            print(
                "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
            )
        }
    }

    @SourceOfTruth public var state: State

    private var store: InternalStore<State>
    private var cancelation: Cancellable?

    public init(initial state: State) {
        guard ProcessInfo.processInfo.isRunningTests else {
            fatalError("TestStore is only for using in Test targets")
        }

        var mutableState = state
        mutableState.initialSetup()

        let store = InternalStore(initial: mutableState, loggers: [TestStoreLogger()])
        self.store = store
        self._state = .init(wrappedValue: mutableState, store: store)

        self.cancelation = store.subject.publisher
            .map(\.0)
            .assign(to: \.state, on: self)
    }

    public func subscribe(build: (_ store: any Store<State>) -> some Middleware<State>) async {
        await store.subscribe(build(store))
    }

    public func subscribe(buildMiddlewares: (_ store: any Store<State>) -> [any _Middleware<State>]) async {
        await store.subscribe(buildMiddlewares(store))
    }

    public func dispatch(_ action: some Action, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) async {
        await store.dispatch(InternalAction(action, fileName: fileName, functionName: functionName, lineNumber: lineNumber))
    }

    public func wait() {
        TestGroup.shared.wait()
    }
}

public extension TestStore {
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: M.buildTestEnvironment(for: store))
        }
    }

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, environment: M.Environment) async where M.State == State,
        M: EnvironmentMiddleware
    {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment)
        }
    }
}

public extension TestStore {
    func subscribe(@MiddlewareBuilder<State> build: (_ store: any Store<State>) -> [MiddlewareWrapper<State>]) async {
        await self.subscribe(buildMiddlewares: { store in
            build(store).map { wrapper in
                wrapper.instance ?? middleware(store: store, type: wrapper.type)
            }
        })
    }

    private func middleware<M: _Middleware<State>>(store: any Store<State>, type: M.Type) -> any _Middleware<State> where M.State == State {
        switch type {
        case let envMiddlewareType as any MiddlewareWithEnvironment<State>.Type:
            envMiddleware(store: store, type: envMiddlewareType)
        default:
            type.init(store: store)
        }
    }

    private func envMiddleware<M: MiddlewareWithEnvironment<State>>(store: any Store<State>, type: M.Type) -> any _Middleware<State>
        where M.State == State
    {
        type.init(store: store, environment: type.buildTestEnvironment(for: store))
    }
}
