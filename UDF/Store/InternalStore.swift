//
//  InternalStore.swift
//
//
//  Created by Max Kuznetsov on 26.10.2022.
//

import Combine
import Foundation
import SwiftUI

actor InternalStore<State: AppReducer>: Store {
    var state: State

    nonisolated let subject = SendableSubject<(State, State, Animation?), Never>()

    var middlewares: OrderedSet<AnyMiddleware> = []
    private let storeQueue: StoreQueue = .init()
    private let delayQueue: DelayQueue = .init()
    private let logDistributor: LogDistributor

    init(initial state: State, loggers: [ActionLogger]) {
        self.state = state
        self.logDistributor = LogDistributor(loggers: loggers)
    }

    func dispatch(_ internalAction: InternalAction) async {
        await self.reduce(internalAction)
    }

    nonisolated func dispatch(_ action: some Action, priority: ActionPriority, fileName: String, functionName: String, lineNumber: Int) {
        TestGroup.shared.enter()
        let internalActions = prepareActionsToReduce(action, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        for internalAction in internalActions {
            let storeOperation = StoreOperation(priority: .init(priority)) { [weak self] in
                await self?.reduce(internalAction)
            }

            if let delay = internalAction.delay {
                let delayedOperation = DelayedOperation(delay: delay, priority: .init(priority))
                // Keep dependency between operations
                storeOperation.addDependency(delayedOperation)

                // Enqueue delay on a parallel delay queue
                delayQueue.addOperation(delayedOperation)

                // Enqueue the actual mutation on a strictly serial store queue
                storeQueue.addOperation(storeOperation)
            } else {
                storeQueue.addOperation(storeOperation)
            }
        }
    }

    func subscribe(_ middleware: some _Middleware<State>) async {
        middlewares.append(AnyMiddleware(middleware))

        await initialNotify(middleware: middleware, state: self.state)
    }

    func subscribe(_ middlewares: [any _Middleware<State>]) async {
        for middleware in middlewares {
            await subscribe(middleware)
        }
    }
}

// MARK: Help Methods
private extension InternalStore {
    func mutate(state: State, animation: Animation?) {
        subject.send((state, self.state, animation))
        self.state = state
    }

    func reduce(_ action: InternalAction) async {
        let unwrappedActions = action.unwrapActions()
        let reduceResult = await reduceActionsInReducers(actions: unwrappedActions)

        if reduceResult.mutated {
            mutate(state: reduceResult.newState, animation: nil)
        }

//        await notifyMiddlewares(unwrappedActions, oldState: reduceResult.oldState, newState: reduceResult.newState)
        for anyMiddleware in middlewares {
            let middleware = anyMiddleware.middleware

            switch middleware {
            case let middleware as any Middleware<State>:
                await notify(middleware: middleware, actions: unwrappedActions, oldState: reduceResult.oldState, newState: reduceResult.newState)

            default:
                continue
            }
        }
    }

    func reduceActionsInReducers(actions: [InternalAction]) async -> (oldState: State, newState: State, mutated: Bool) {
        var newState = self.state
        let oldState = self.state
        var mutated = false

        for unwrappedAction in actions {
            logDistributor.distribute(action: unwrappedAction)

            if let animation = unwrappedAction.animation {
                if newState.reduce(unwrappedAction.value) {
                    mutate(state: newState, animation: animation)
                    await notifyMiddlewares([unwrappedAction], oldState: oldState, newState: newState)
                }
            } else {
                if newState.reduce(unwrappedAction.value) {
                    mutated = true
                }
            }
        }

        return (oldState, newState, mutated)
    }

    nonisolated func prepareActionsToReduce(
        _ action: some Action,
        fileName: String,
        functionName: String,
        lineNumber: Int
    ) -> [InternalAction] {
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

        let delayedActions = internalAction.findDelayedActions()
        let filteredActions = internalAction.unwrapActions(isIncluded: { $0.delay == nil })

        if !filteredActions.isEmpty {
            return [InternalAction(
                ActionGroup(internalActions: filteredActions),
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )] + delayedActions
        }

        return delayedActions
    }
}

// MARK: Notify Methods
private extension InternalStore {
    func notifyMiddlewares(_ actions: [InternalAction], oldState: State, newState: State) async {
        for anyMiddleware in middlewares {
            let middleware = anyMiddleware.middleware

            switch middleware {
            case let middleware as any Middleware<State>:
                await notify(middleware: middleware, actions: actions, oldState: oldState, newState: newState)

            default:
                continue
            }
        }
    }

    func notify<M: MiddlewareProtocol>(middleware: M, actions: [InternalAction], oldState: State, newState: State) async where M.State == State {
        let status = middleware.status(for: newState)
        middleware.queue.async {
            if status == .suspend {
                middleware.cancelAll()
            } else {
                for action in actions {
                    middleware.reduce(action.value, for: newState)
                }
            }
        }

        let oldScope = middleware.scope(for: oldState)
        let newScope = middleware.scope(for: newState)
        let oldStatus = middleware.status(for: oldState)
        let newStatus = middleware.status(for: newState)

        var callObserve = false

        if oldStatus == .suspend, newStatus != oldStatus {
            callObserve = true
        } else if oldStatus != .suspend, newStatus == .suspend {
            middleware.cancelAll()
        } else if newStatus == .active {
            callObserve = !oldScope.isEqual(newScope)
        }

        if callObserve {
            middleware.queue.async {
                middleware.observe(state: newState)
            }
        }
    }

    func initialNotify(middleware: some _Middleware<State>, state: State) async {
        let status = middleware.status(for: state)
        guard status == .active else {
            return
        }

        if let unifiedMiddleware = middleware as? any Middleware<State> {
            middleware.queue.async {
                unifiedMiddleware.observe(state: state)
            }
        }
    }
}
