//
//  InternalStore.swift
//
//
//  Created by Max Kuznetsov on 26.10.2022.
//

import Foundation
import Combine
import SwiftUI

actor InternalStore<State: AppReducer>: Store {
    var state: State

    let subject: PassthroughSubject<(State, State, Animation?), Never> = .init()

    var loggers: [ActionLogger]
    var middlewares: [any Middleware] = []
    private let storeQueue: StoreQueue = .init()
    private let logDistributor: LogDistributor

    init(initial state: State, loggers: [ActionLogger]) throws {
        self.loggers = loggers
        self.state = state
        self.logDistributor = LogDistributor(loggers: loggers)
    }

    func dispatch(_ internalAction: InternalAction) async {
        await self.reduce(internalAction)
    }

    nonisolated func dispatch(_ action: some Action, priority: ActionPriority, fileName: String, functionName: String, lineNumber: Int) {
        XCTestGroup.enter()
        let internalAction: InternalAction = {
            if let internalAction = action as? InternalAction {
                return internalAction
            }

            return InternalAction(
                action,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }()

        storeQueue.addOperation(
            StoreOperation(priority: .init(priority)) { [weak self] in
                await self?.reduce(internalAction)
                XCTestGroup.leave()
            }
        )
    }

    func subscribe(_ middleware: some Middleware<State>) async {
        middlewares.append(middleware)

        switch middleware {
        case let middleware as any ObservableMiddleware<State>:
            await initialNotifyObservable(middleware: middleware, state: Box(self.state))

        default:
            break
        }
    }

    func subscribe(_ middlewares: [any Middleware<State>]) async {
        for middleware in middlewares {
            await subscribe(middleware)
        }
    }
}

// MARK: Help Methods
private extension InternalStore {
    func mutate(state: Box<State>, animation: Animation?) {
        subject.send((state.value, self.state, animation))
        self.state = state.value
    }

    func reduce(_ action: InternalAction) async {
        let unwrappedActions = action.unwrapActions()
        let reduceResult = await reduceActionsInReducers(actions: unwrappedActions)

        if reduceResult.mutated {
            mutate(state: reduceResult.newState, animation: nil)
        }

        await notifyMiddlewares(unwrappedActions, oldState: reduceResult.oldState, newState: reduceResult.newState)
    }

    func reduceActionsInReducers(actions: [InternalAction]) async -> (oldState: Box<State>, newState: Box<State>, mutated: Bool) {
        var newState = Box(self.state)
        let oldState = Box(self.state)
        var mutated = false

        for unwrappedAction in actions {
            logDistributor.distribute(action: unwrappedAction)

            if let animation = unwrappedAction.animation {
                if newState.value.reduce(unwrappedAction.value) {
                    mutate(state: newState, animation: animation)
                    await notifyMiddlewares([unwrappedAction], oldState: oldState, newState: newState)
                }
            } else {
                if newState.value.reduce(unwrappedAction.value) {
                    mutated = true
                }
            }
        }

        return (oldState, newState, mutated)
    }
}

// MARK: Notify Methods
private extension InternalStore {

    func notifyMiddlewares(_ actions: [InternalAction], oldState: Box<State>, newState: Box<State>) async {
        for middleware in middlewares {
            switch middleware {
            case let middleware as any ReducibleMiddleware<State>:
                await notifyReducible(middleware: middleware, actions: actions, newState: newState)

            case let middleware as any ObservableMiddleware<State>:
                await notifyObservable(middleware: middleware, oldState: oldState, newState: newState)

            default:
                continue
            }
        }
    }

    func notifyReducible<CR: ReducibleMiddleware>(middleware: CR, actions: [InternalAction], newState: Box<State>) async where CR.State == State {
        let status = middleware.status(for: newState.value)

        await safetyCall(queue: middleware.queue) {
            if status == .suspend {
                middleware.cancelAll()
            } else {
                actions.forEach { action in
                    middleware.reduce(action.value, for: newState.value)
                }
            }
        }
    }

    func initialNotifyObservable<CO: ObservableMiddleware>(middleware: CO, state: Box<State>) async where CO.State == State {
        let status = middleware.status(for: state.value)
        guard status == .active else {
            return
        }

        let stateValue = state.value
        await safetyCall(queue: middleware.queue) {
            middleware.observe(state: stateValue)
        }
    }

    func notifyObservable<CO: ObservableMiddleware>(middleware: CO, oldState: Box<State>, newState: Box<State>) async where CO.State == State {
        let oldScope = middleware.scope(for: oldState.value)
        let newScope = middleware.scope(for: newState.value)

        let oldStatus = middleware.status(for: oldState.value)
        let newStatus = middleware.status(for: newState.value)

        var callObserve = false

        if oldStatus == .suspend, newStatus != oldStatus {
            callObserve = true
        } else if oldStatus != .suspend, newStatus == .suspend {
            middleware.cancelAll()

        } else if newStatus == .active {
            callObserve = !oldScope.isEqual(newScope)
        }

        if callObserve {
            let newStateValue = newState.value
            await safetyCall(queue: middleware.queue) {
                middleware.observe(state: newStateValue)
            }
        }
    }
}

fileprivate func safetyCall(queue: DispatchQueue, block: @Sendable @escaping () -> Void) async {
    await withUnsafeContinuation { continuation in
        if queue == .main {
            queue.async {
                block()
                continuation.resume()
            }
        } else {
            queue.sync {
                block()
                continuation.resume()
            }
        }
    }
}

final class Ref<T> {
    var value: T
    init(value: T) {
        self.value = value
    }
}

struct Box<T> {
    private var ref: Ref<T>
    init(_ value: T) {
        ref = Ref(value: value)
    }
    var value: T {
        get { ref.value }
        set {
            guard isKnownUniquelyReferenced(&ref) else {
                ref = Ref(value: newValue)
                return
            }
            ref.value = newValue
        }
    }
}
