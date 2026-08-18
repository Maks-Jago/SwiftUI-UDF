//
//  TestStore.swift
//
//
//  Created by Max Kuznetsov on 05.10.2021.
//

import Combine
import SwiftUI

/// A global actor that isolates access to test-only store state, keeping `TestStore` operations
/// serialized independently from the app's own actors.
@globalActor public actor TestStoreActor {
    public static let shared = TestStoreActor()
}

/// A lightweight, in-memory `Store` implementation intended for unit tests.
///
/// `TestStore` lets you drive an `AppReducer` state through reducers and middlewares without
/// standing up a full `EnvironmentStore`, so you can dispatch actions, subscribe middlewares,
/// and assert on the resulting state changes in isolation.
///
/// - Important: `TestStore` calls `fatalError` if it is initialized outside of a test target.
///
/// Example usage:
/// ```swift
/// let testStore = TestStore(initial: AppState())
/// await testStore.subscribe(MyMiddleware.self)
/// await testStore.dispatch(Actions.DidTapButton())
/// testStore.wait()
/// XCTAssertEqual(testStore.state.someValue, expected)
/// ```
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

    /// The current state of the test store, kept in sync with the underlying `InternalStore`.
    @SourceOfTruth public var state: State

    private var store: InternalStore<State>
    private var cancelation: Cancellable?

    /// Creates a `TestStore` with the given initial state, running `initialSetup()` on it before use.
    ///
    /// - Parameter state: The initial `State` value to seed the store with.
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

    /// Subscribes a single middleware, built from a closure, to the test store.
    ///
    /// - Parameter build: A closure that creates the middleware instance for the given store.
    public func subscribe(build: (_ store: any Store<State>) -> some Middleware<State>) async {
        await store.subscribe(build(store))
    }

    /// Subscribes a list of middlewares, built from a closure, to the test store.
    ///
    /// - Parameter buildMiddlewares: A closure that creates the middleware instances for the given store.
    public func subscribe(buildMiddlewares: (_ store: any Store<State>) -> [any _Middleware<State>]) async {
        await store.subscribe(buildMiddlewares(store))
    }

    /// Dispatches an action to the test store and registers it with the current `TestGroup`
    /// so that `wait(additionalSleepFor:)` can await its effects.
    ///
    /// - Parameters:
    ///   - action: The action to dispatch.
    ///   - fileName: The name of the file where the action is dispatched. Defaults to the caller's file.
    ///   - functionName: The name of the function where the action is dispatched. Defaults to the caller's function.
    ///   - lineNumber: The line number where the action is dispatched. Defaults to the caller's line.
    public func dispatch(_ action: some Action, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) async {
        TestGroup.instance(for: store).enter()
        await store.dispatch(InternalAction(action, fileName: fileName, functionName: functionName, lineNumber: lineNumber))
    }

    /// Blocks the current thread until all dispatched actions and their side effects have completed.
    ///
    /// - Parameter additionalSleepFor: An extra delay, in seconds, to wait after all effects complete. Defaults to `0`.
    public func wait(additionalSleepFor: TimeInterval = 0) {
        TestGroup.instance(for: store).wait(additionalSleepFor: additionalSleepFor)
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

public extension TestStore {
    func didLoad<C: BindableContainer>(_ containerType: C.Type, id: C.ID, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) async {
        await self.dispatch(Actions._OnContainerDidLoad(containerType: containerType, id: id), fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
    
    func didUnload<C: BindableContainer>(_ containerType: C.Type, id: C.ID, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) async {
        await self.dispatch(Actions._OnContainerDidUnLoad(containerType: containerType, id: id), fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
}

public extension TestStore {
    func dispatch(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        @ActionGroupBuilder _ builder: () -> ActionGroup
    ) async {
        await dispatch(builder(), fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
}
