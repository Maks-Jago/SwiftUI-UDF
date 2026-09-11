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

@testable import UDF
import Foundation
import os
import Testing
import UDFSwiftTesting

@Suite
struct FeatureMiddlewareDependencyTests {
    @TestStoreActor
    @Test("Feature registration preserves shared services and exact queue instances")
    func registrationPreservesDependencyIdentity() async throws {
        let store = TestStore(initial: AppState())
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
        let firstEnvironment: FirstEnvironment = try #require(firstMiddleware.environment)
        let secondEnvironment: SecondEnvironment = try #require(secondMiddleware.environment)

        #expect(firstEnvironment.service === AppDependencies.sharedService)
        #expect(secondEnvironment.service === AppDependencies.sharedService)
        #expect(firstEnvironment.service === secondEnvironment.service)

        #expect(firstMiddleware.queue === AppDependencies.firstQueue)
        #expect(secondMiddleware.queue === AppDependencies.secondQueue)
    }

    @Test(
        "Feature middleware reduce and observe callbacks use their exact injected queues with TestStore",
        .timeLimit(.minutes(1))
    )
    func callbacksExecuteOnExactInjectedQueues() async {
        let firstQueue = DispatchQueue(label: QueueLabel.shared)
        let secondQueue = DispatchQueue(label: QueueLabel.shared)
        let store = await TestStore(initial: AppState())

        await confirmation("All callbacks execute on their injected queue", expectedCount: 4) { confirm in
            let firstEnv = FirstEnvironment(
                service: AppDependencies.sharedService,
                onReduce: {
                    dispatchPrecondition(condition: .onQueue(firstQueue))
                    confirm()
                },
                onObserve: {
                    dispatchPrecondition(condition: .onQueue(firstQueue))
                    confirm()
                }
            )
            let secondEnv = SecondEnvironment(
                service: AppDependencies.sharedService,
                onReduce: {
                    dispatchPrecondition(condition: .onQueue(secondQueue))
                    confirm()
                },
                onObserve: {
                    dispatchPrecondition(condition: .onQueue(secondQueue))
                    confirm()
                }
            )

            #expect(firstEnv.service === secondEnv.service)

            await store.subscribe(build: { store in
                FirstFeatureMiddleware(
                    store: store,
                    environment: firstEnv,
                    queue: firstQueue
                )
                SecondFeatureMiddleware(
                    store: store,
                    environment: secondEnv,
                    queue: secondQueue
                )
            })

            await store.dispatch(TriggerAction())
            await store.wait()
        }
    }

    @Test(
        "EnvironmentStore dispatches feature middleware reduce and observe on exact injected queues",
        .timeLimit(.minutes(1))
    )
    func environmentStoreExecutesCallbacksOnExactInjectedQueues() async {
        let firstQueue = AppDependencies.firstQueue
        let secondQueue = AppDependencies.secondQueue
        let callbackCount = OSAllocatedUnfairLock(initialState: 0)

        await confirmation("EnvironmentStore callbacks execute on exact queues", expectedCount: 4) { confirm in
            let testEnvironment = TestEnvironment(
                first: FirstEnvironment(
                    service: AppDependencies.sharedService,
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
                second: SecondEnvironment(
                    service: AppDependencies.sharedService,
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
                store.dispatch(TriggerAction())

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
        let store = await TestStore(initial: AppState())

        await confirmation("Shared queue callbacks execute on shared queue", expectedCount: 4) { confirm in
            let firstEnv = FirstEnvironment(
                service: AppDependencies.sharedService,
                onReduce: {
                    dispatchPrecondition(condition: .onQueue(sharedQueue))
                    confirm()
                },
                onObserve: {
                    dispatchPrecondition(condition: .onQueue(sharedQueue))
                    confirm()
                }
            )
            let secondEnv = SecondEnvironment(
                service: AppDependencies.sharedService,
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
                FirstFeatureMiddleware(store: store, environment: firstEnv, queue: sharedQueue)
                SecondFeatureMiddleware(store: store, environment: secondEnv, queue: sharedQueue)
            })

            await store.dispatch(TriggerAction())
            await store.wait()
        }
    }
}

// MARK: - Feature Composition Fixtures

private extension FeatureMiddlewareDependencyTests {
    enum QueueLabel {
        static let shared = "FeatureMiddlewareDependencyTests.same-label"
    }

    final class SharedService: Sendable {}

    enum AppDependencies {
        static let sharedService = SharedService()

        static let firstQueue = DispatchQueue(label: QueueLabel.shared)
        static let secondQueue = DispatchQueue(label: QueueLabel.shared)
    }

    struct AppState: AppReducer {
        var triggerForm = TriggerForm()
        var firstFeature = FirstFeatureState()
        var secondFeature = SecondFeatureState()
    }

    struct TriggerForm: Reducible {
        var isTriggered = false

        mutating func reduce(_ action: some Action) {
            guard action is TriggerAction else {
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
                environment: TestEnvironmentContext.environment?.first ?? FirstEnvironment(service: AppDependencies.sharedService),
                queue: AppDependencies.firstQueue
            )
        }
    }

    struct SecondFeatureState: Reducible, MiddlewareRegistering {
        @MiddlewareBuilder<AppState>
        static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
            SecondFeatureMiddleware(
                store: store,
                environment: TestEnvironmentContext.environment?.second ?? SecondEnvironment(service: AppDependencies.sharedService),
                queue: AppDependencies.secondQueue
            )
        }
    }
}

// MARK: - Middleware Fixtures

private extension FeatureMiddlewareDependencyTests {
    struct FirstEnvironment: Sendable {
        let service: SharedService
        var onReduce: (@Sendable () -> Void)?
        var onObserve: (@Sendable () -> Void)?
    }

    struct SecondEnvironment: Sendable {
        let service: SharedService
        var onReduce: (@Sendable () -> Void)?
        var onObserve: (@Sendable () -> Void)?
    }

    struct TestEnvironment: Sendable {
        let first: FirstEnvironment
        let second: SecondEnvironment
    }

    enum TestEnvironmentContext {
        @TaskLocal static var environment: TestEnvironment?
    }

    struct TriggerAction: Action {}

    final class FirstFeatureMiddleware: FeatureMiddleware<AppState>, @unchecked Sendable {
        var environment: FirstEnvironment!

        func scope(for state: AppState) -> Scope {
            state.triggerForm
        }

        func reduce(_ action: some Action, for state: AppState) {
            guard action is TriggerAction else {
                return
            }

            environment.onReduce?()
        }

        func observe(state: AppState) {
            guard state.triggerForm.isTriggered else {
                return
            }

            environment.onObserve?()
        }
    }

    final class SecondFeatureMiddleware: FeatureMiddleware<AppState>, @unchecked Sendable {
        var environment: SecondEnvironment!

        func scope(for state: AppState) -> Scope {
            state.triggerForm
        }

        func reduce(_ action: some Action, for state: AppState) {
            guard action is TriggerAction else {
                return
            }

            environment.onReduce?()
        }

        func observe(state: AppState) {
            guard state.triggerForm.isTriggered else {
                return
            }

            environment.onObserve?()
        }
    }
}
