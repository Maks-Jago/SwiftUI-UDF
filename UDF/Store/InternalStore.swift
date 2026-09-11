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

    private(set) var middlewares: OrderedSet<AnyMiddleware> = []
    private let storeQueue: StoreQueue = .init()
    private let delayQueue: DelayQueue = .init()
    private let logDistributor: LogDistributor

    init(initial state: State, loggers: [ActionLogger]) {
        self.state = state
        self.logDistributor = LogDistributor(loggers: loggers)
    }

    func dispatch(_ internalAction: InternalAction) {
        self.reduce(internalAction)
        TestGroup.instance(for: self).leave()
    }

    nonisolated func dispatch(_ action: some Action, priority: ActionPriority, fileName: String, functionName: String, lineNumber: Int) {
        let internalActions = prepareActionsToReduce(action, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        for internalAction in internalActions {
            let testGroupKey = TestGroup.enter(for: self)
            let storeOperation = StoreOperation(priority: .init(priority)) {
                TestGroup.instanceFor(key: testGroupKey).leave()
            } closure: { [weak self] in
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

        initialNotify(middleware: middleware, state: self.state)
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
        let old = self.state
        self.state = state
        subject.send((state, old, animation))
    }

    func reduce(_ action: InternalAction) {
        let unwrappedActions = action.unwrapActions()
        let reduceResult = reduceActionsInReducers(actions: unwrappedActions)

        if reduceResult.mutated {
            mutate(state: reduceResult.newState, animation: nil)
        }

        let middlewaresSnapshot = Array(self.middlewares)
        for anyMiddleware in middlewaresSnapshot {
            let middleware = anyMiddleware.middleware

            switch middleware {
            case let middleware as any MiddlewareProtocol<State>:
                notify(middleware: middleware, actions: unwrappedActions, oldState: reduceResult.oldState, newState: reduceResult.newState)

            default:
                continue
            }
        }
    }

    func reduceActionsInReducers(actions: [InternalAction]) -> (oldState: State, newState: State, mutated: Bool) {
        var newState = self.state
        let oldState = self.state
        var mutated = false

        for unwrappedAction in actions {
            logDistributor.distribute(action: unwrappedAction)

            if let animation = unwrappedAction.animation {
                if newState.reduce(unwrappedAction.value) {
                    mutate(state: newState, animation: animation)
                    notifyMiddlewares([unwrappedAction], oldState: oldState, newState: newState)
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
    func notifyMiddlewares(_ actions: [InternalAction], oldState: State, newState: State) {
        for anyMiddleware in middlewares {
            let middleware = anyMiddleware.middleware

            switch middleware {
            case let middleware as any MiddlewareProtocol<State>:
                notify(middleware: middleware, actions: actions, oldState: oldState, newState: newState)

            default:
                continue
            }
        }
    }

    func notify<M: MiddlewareProtocol>(middleware: M, actions: [InternalAction], oldState: State, newState: State) where M.State == State {
        let oldScope = middleware.scope(for: oldState)
        let newScope = middleware.scope(for: newState)

        let oldStatus = middleware.status(for: oldState)
        let newStatus = middleware.status(for: newState)

        let testGroupKey = TestGroup.enter(for: self)
        middleware.queue.async {
            if newStatus == .suspend {
                middleware.cancelAll()
            } else {
                for action in actions {
                    middleware.reduce(action.value, for: newState)
                }
            }
            TestGroup.instanceFor(key: testGroupKey).leave()
        }

        var callObserve = false

        if oldStatus == .suspend, newStatus != oldStatus {
            callObserve = true
        } else if oldStatus != .suspend, newStatus == .suspend {
            middleware.queue.async {
                middleware.cancelAll()
            }
        } else if newStatus == .active {
            callObserve = !oldScope.isEqual(newScope)
        }

        if callObserve {
            TestGroup.instanceFor(key: testGroupKey).enter()
            middleware.queue.async {
                middleware.observe(state: newState)
                TestGroup.instanceFor(key: testGroupKey).leave()
            }
        }
    }

    func initialNotify(middleware: some _Middleware<State>, state: State) {
        let status = middleware.status(for: state)
        guard status == .active else {
            return
        }

        if let unifiedMiddleware = middleware as? any MiddlewareProtocol<State> {
            middleware.queue.async {
                unifiedMiddleware.observe(state: state)
            }
        }
    }
}
