//===--- FeatureMiddlewareDependencyTests.swift ------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import os
import Testing
@testable import UDF
import UDFSwiftTesting

struct FeatureMiddlewareDependencyTests {
    @TestStoreActor
    @Test("Feature registration preserves shared services and exact queue instances")
    func registrationPreservesDependencyIdentity() async throws {
        let store = TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )
        var wrappers: [MiddlewareWrapper<AppState>] = []

        await store.subscribe { store in
            wrappers = FirstFeatureState.registerMiddlewares(in: store)
                + SecondFeatureState.registerMiddlewares(in: store)
            return wrappers
        }

        #expect(wrappers.count == 2)

        let firstMiddleware = try #require(
            wrappers.compactMap { $0.instance as? FirstFeatureMiddleware }.first
        )
        let secondMiddleware = try #require(
            wrappers.compactMap { $0.instance as? SecondFeatureMiddleware }.first
        )
        let firstEnvironment: FirstFeatureEnvironment = try #require(firstMiddleware.environment)
        let secondEnvironment: SecondFeatureEnvironment = try #require(secondMiddleware.environment)

        #expect(firstEnvironment.dependency === AppDependencies.sharedDependency)
        #expect(secondEnvironment.dependency === AppDependencies.sharedDependency)
        #expect(firstEnvironment.dependency === secondEnvironment.dependency)

        #expect(firstMiddleware.queue === AppDependencies.firstFeatureQueue)
        #expect(secondMiddleware.queue === AppDependencies.secondFeatureQueue)
    }

    @Test(
        "Feature middleware reduce and observe callbacks use their exact injected queues with TestStore",
        .timeLimit(.minutes(1))
    )
    func callbacksExecuteOnExactInjectedQueues() async {
        let firstQueue = DispatchQueue(label: QueueLabel.shared)
        let secondQueue = DispatchQueue(label: QueueLabel.shared)
        let store = await TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )

        await confirmation("All callbacks execute on their injected queue", expectedCount: 4) { confirm in
            let firstEnvironment = FirstFeatureEnvironment(
                dependency: AppDependencies.sharedDependency,
                onReduce: {
                    dispatchPrecondition(condition: .onQueue(firstQueue))
                    confirm()
                },
                onObserve: {
                    dispatchPrecondition(condition: .onQueue(firstQueue))
                    confirm()
                }
            )
            let secondEnvironment = SecondFeatureEnvironment(
                dependency: AppDependencies.sharedDependency,
                onReduce: {
                    dispatchPrecondition(condition: .onQueue(secondQueue))
                    confirm()
                },
                onObserve: {
                    dispatchPrecondition(condition: .onQueue(secondQueue))
                    confirm()
                }
            )

            #expect(firstEnvironment.dependency === secondEnvironment.dependency)

            await store.subscribe(build: { store in
                FirstFeatureMiddleware(
                    store: store,
                    environment: firstEnvironment,
                    queue: firstQueue
                )
                SecondFeatureMiddleware(
                    store: store,
                    environment: secondEnvironment,
                    queue: secondQueue
                )
            })

            await store.dispatch(InvokeMiddlewareCallbacks())
            await store.wait()
        }
    }

    @Test(
        "EnvironmentStore dispatches feature middleware reduce and observe on exact injected queues",
        .timeLimit(.minutes(1))
    )
    func environmentStoreExecutesCallbacksOnExactInjectedQueues() async {
        let firstQueue = AppDependencies.firstFeatureQueue
        let secondQueue = AppDependencies.secondFeatureQueue
        let callbackCount = OSAllocatedUnfairLock(initialState: 0)

        await confirmation("EnvironmentStore callbacks execute on exact queues", expectedCount: 4) { confirm in
            let testEnvironment = TestEnvironment(
                first: FirstFeatureEnvironment(
                    dependency: AppDependencies.sharedDependency,
                    onReduce: {
                        dispatchPrecondition(condition: .onQueue(firstQueue))
                        confirm()
                        callbackCount.withLock { $0 += 1 }
                    },
                    onObserve: {
                        dispatchPrecondition(condition: .onQueue(firstQueue))
                        confirm()
                        callbackCount.withLock { $0 += 1 }
                    }
                ),
                second: SecondFeatureEnvironment(
                    dependency: AppDependencies.sharedDependency,
                    onReduce: {
                        dispatchPrecondition(condition: .onQueue(secondQueue))
                        confirm()
                        callbackCount.withLock { $0 += 1 }
                    },
                    onObserve: {
                        dispatchPrecondition(condition: .onQueue(secondQueue))
                        confirm()
                        callbackCount.withLock { $0 += 1 }
                    }
                )
            )

            await TestEnvironmentContext.$environment.withValue(testEnvironment) {
                let store = EnvironmentStore(initial: AppState(), loggers: [])
                store.dispatch(InvokeMiddlewareCallbacks())

                let executed = await waitForCondition(timeout: 5) {
                    callbackCount.withLock { $0 == 4 }
                }
                #expect(executed)
            }
        }
    }

    @Test(
        "Multiple feature middlewares sharing the same queue instance execute on that queue",
        .timeLimit(.minutes(1))
    )
    func sharedQueueExecutesCallbacksOnSameQueueInstance() async {
        let sharedQueue = DispatchQueue(label: "FeatureMiddlewareDependencyTests.shared-work-queue")
        let store = await TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )

        await confirmation("Shared queue callbacks execute on shared queue", expectedCount: 4) { confirm in
            let firstEnvironment = FirstFeatureEnvironment(
                dependency: AppDependencies.sharedDependency,
                onReduce: {
                    dispatchPrecondition(condition: .onQueue(sharedQueue))
                    confirm()
                },
                onObserve: {
                    dispatchPrecondition(condition: .onQueue(sharedQueue))
                    confirm()
                }
            )
            let secondEnvironment = SecondFeatureEnvironment(
                dependency: AppDependencies.sharedDependency,
                onReduce: {
                    dispatchPrecondition(condition: .onQueue(sharedQueue))
                    confirm()
                },
                onObserve: {
                    dispatchPrecondition(condition: .onQueue(sharedQueue))
                    confirm()
                }
            )

            await store.subscribe(build: { store in
                FirstFeatureMiddleware(store: store, environment: firstEnvironment, queue: sharedQueue)
                SecondFeatureMiddleware(store: store, environment: secondEnvironment, queue: sharedQueue)
            })

            await store.dispatch(InvokeMiddlewareCallbacks())
            await store.wait()
        }
    }
}

// MARK: - Feature Composition Fixtures

private extension FeatureMiddlewareDependencyTests {
    enum QueueLabel {
        static let shared = "FeatureMiddlewareDependencyTests.same-label"
    }

    final class SharedDependency: Sendable {}

    enum AppDependencies {
        static let sharedDependency = SharedDependency()

        static let firstFeatureQueue = DispatchQueue(label: QueueLabel.shared)
        static let secondFeatureQueue = DispatchQueue(label: QueueLabel.shared)
    }

    struct AppState: AppReducer {
        var callbackInvocation = CallbackInvocationForm()
        var firstFeature = FirstFeatureState()
        var secondFeature = SecondFeatureState()
    }

    struct CallbackInvocationForm: Reducible {
        var isTriggered = false

        mutating func reduce(_ action: some Action) {
            guard action is InvokeMiddlewareCallbacks else {
                return
            }

            isTriggered = true
        }
    }

    struct FirstFeatureState: Reducible, MiddlewareRegistering {
        @MiddlewareBuilder<AppState>
        static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
            FirstFeatureMiddleware(
                store: store,
                environment: TestEnvironmentContext.environment?.first
                    ?? FirstFeatureEnvironment(dependency: AppDependencies.sharedDependency),
                queue: AppDependencies.firstFeatureQueue
            )
        }
    }

    struct SecondFeatureState: Reducible, MiddlewareRegistering {
        @MiddlewareBuilder<AppState>
        static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
            SecondFeatureMiddleware(
                store: store,
                environment: TestEnvironmentContext.environment?.second
                    ?? SecondFeatureEnvironment(dependency: AppDependencies.sharedDependency),
                queue: AppDependencies.secondFeatureQueue
            )
        }
    }
}

// MARK: - Middleware Fixtures

private extension FeatureMiddlewareDependencyTests {
    struct FirstFeatureEnvironment: Sendable {
        let dependency: SharedDependency
        var onReduce: (@Sendable () -> Void)?
        var onObserve: (@Sendable () -> Void)?
    }

    struct SecondFeatureEnvironment: Sendable {
        let dependency: SharedDependency
        var onReduce: (@Sendable () -> Void)?
        var onObserve: (@Sendable () -> Void)?
    }

    struct TestEnvironment: Sendable {
        let first: FirstFeatureEnvironment
        let second: SecondFeatureEnvironment
    }

    enum TestEnvironmentContext {
        @TaskLocal static var environment: TestEnvironment?
    }

    struct InvokeMiddlewareCallbacks: Action {}

    final class FirstFeatureMiddleware: Middleware<AppState>, @unchecked Sendable {
        var environment: FirstFeatureEnvironment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> FirstFeatureEnvironment {
            FirstFeatureEnvironment(dependency: AppDependencies.sharedDependency)
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> FirstFeatureEnvironment {
            FirstFeatureEnvironment(dependency: AppDependencies.sharedDependency)
        }

        func scope(for state: AppState) -> Scope {
            state.callbackInvocation
        }

        func reduce(_ action: some Action, for state: AppState) {
            guard action is InvokeMiddlewareCallbacks else {
                return
            }

            environment.onReduce?()
        }

        func observe(state: AppState) {
            guard state.callbackInvocation.isTriggered else {
                return
            }

            environment.onObserve?()
        }
    }

    final class SecondFeatureMiddleware: Middleware<AppState>, @unchecked Sendable {
        var environment: SecondFeatureEnvironment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> SecondFeatureEnvironment {
            SecondFeatureEnvironment(dependency: AppDependencies.sharedDependency)
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> SecondFeatureEnvironment {
            SecondFeatureEnvironment(dependency: AppDependencies.sharedDependency)
        }

        func scope(for state: AppState) -> Scope {
            state.callbackInvocation
        }

        func reduce(_ action: some Action, for state: AppState) {
            guard action is InvokeMiddlewareCallbacks else {
                return
            }

            environment.onReduce?()
        }

        func observe(state: AppState) {
            guard state.callbackInvocation.isTriggered else {
                return
            }

            environment.onObserve?()
        }
    }
}
