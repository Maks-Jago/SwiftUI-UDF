//===--- FeatureServicesDependencyTests.swift --------------------===//
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
import SwiftUI
import Testing
@testable import UDF
import UDFSwiftTesting

@Suite("Feature services and shared dependencies")
struct FeatureServicesDependencyTests {
    @TestStoreActor
    @Test("AppServices injects the same service singleton into multiple feature environments")
    func appServicesInjectsSameSingletonAcrossFeatures() async throws {
        let service = SharedToggleService()

        await AppServicesContext.$service.withValue(service) {
            let store = TestStore(initial: AppState())
            var wrappers: [MiddlewareWrapper<AppState>] = []

            await store.subscribe { store in
                wrappers = FeatureAState<AppState>.registerMiddlewares(in: store)
                    + FeatureBState<AppState>.registerMiddlewares(in: store)
                return wrappers
            }

            #expect(wrappers.count == 2)

            guard let middlewareA = wrappers.compactMap({ $0.instance as? FeatureAMiddleware<AppState> }).first,
                  let middlewareB = wrappers.compactMap({ $0.instance as? FeatureBMiddleware<AppState> }).first else {
                Issue.record("Expected both middlewares to be present")
                return
            }

            #expect(middlewareA.environment.service === service)
            #expect(middlewareB.environment.service === service)
            #expect(middlewareA.environment.service === middlewareB.environment.service)
        }
    }

    @Test("Cross-feature coordination via shared service reflects in EnvironmentStore state")
    func crossFeatureServiceCoordinationInEnvironmentStore() async {
        let service = SharedToggleService()

        await AppServicesContext.$service.withValue(service) {
            let store = EnvironmentStore(
                initial: AppState(),
                loggers: []
            )

            // 1. Feature A toggles the shared service on
            store.dispatch(Actions.ToggleFeatureA())

            let aToggled = await waitForCondition(timeout: 2) {
                store.state.featureA.form.isToggled == true
                    && service.isToggled == true
            }
            #expect(aToggled)

            // 2. Feature B syncs with the shared service and observes the change
            store.dispatch(Actions.SyncFeatureB())

            let bSynced = await waitForCondition(timeout: 2) {
                store.state.featureB.form.isToggled == true
            }
            #expect(bSynced)

            // 3. Feature A toggles the shared service off
            store.dispatch(Actions.ToggleFeatureA())

            let aToggledOff = await waitForCondition(timeout: 2) {
                store.state.featureA.form.isToggled == false
                    && service.isToggled == false
            }
            #expect(aToggledOff)

            // 4. Feature B syncs again and observes it is now off
            store.dispatch(Actions.SyncFeatureB())

            let bSyncedOff = await waitForCondition(timeout: 2) {
                store.state.featureB.form.isToggled == false
            }
            #expect(bSyncedOff)
        }
    }

    @Test("Concurrent calls on shared service from different middleware queues maintain consistency")
    func concurrentSharedServiceAccess() async {
        let service = SharedToggleService()
        let store = await TestStore(initial: AppState())

        await store.subscribe(build: { store in
            FeatureAMiddleware<AppState>(
                store: store,
                environment: FeatureAEnvironment(service: service),
                queue: DispatchQueue(label: "test.featureA.queue", attributes: .concurrent)
            )
            FeatureBMiddleware<AppState>(
                store: store,
                environment: FeatureBEnvironment(service: service),
                queue: DispatchQueue(label: "test.featureB.queue", attributes: .concurrent)
            )
        })

        // Concurrently dispatch actions to both features
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await store.dispatch(Actions.ToggleFeatureA())
            }
            group.addTask {
                await store.dispatch(Actions.ToggleFeatureB())
            }
        }

        await store.wait()

        let state = await store.state
        #expect(state.featureA.form.executionCount == 1)
        #expect(state.featureB.form.executionCount == 1)
        // Two toggles on an initially false boolean returns false
        #expect(service.isToggled == false)
    }

    @Test("Separate store instances share AppServices but maintain isolated middleware instances")
    func separateStoresShareServicesButIsolateMiddlewares() async throws {
        let service = SharedToggleService()

        await AppServicesContext.$service.withValue(service) {
            let firstStore = EnvironmentStore(initial: AppState(), loggers: [])
            let secondStore = EnvironmentStore(initial: AppState(), loggers: [])

            firstStore.dispatch(Actions.ToggleFeatureA())

            let firstToggled = await waitForCondition(timeout: 2) {
                firstStore.state.featureA.form.isToggled == true
            }
            #expect(firstToggled)

            // Second store's state is independent and isolated
            #expect(secondStore.state.featureA.form.isToggled == false)

            // But the underlying AppServices service was invoked by store 1
            #expect(service.isToggled == true)

            // Cleanup / Toggle back
            firstStore.dispatch(Actions.ToggleFeatureA())
            let cleaned = await waitForCondition(timeout: 2) {
                service.isToggled == false
            }
            #expect(cleaned)
        }
    }
}

// MARK: - AppServices & AppQueues Definitions

private enum AppServicesContext {
    @TaskLocal static var service: SharedToggleService?
}

private enum AppQueues {
    static let featureA = DispatchQueue(label: "app.featureA.queue")
    static let featureB = DispatchQueue(label: "app.featureB.queue")
}

private final class SharedToggleService: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: false)

    var isToggled: Bool {
        lock.withLock { $0 }
    }

    func toggle() {
        lock.withLock { $0.toggle() }
    }
}

private enum AppServices {
    static var service: SharedToggleService {
        AppServicesContext.service ?? defaultService
    }
    private static let defaultService = SharedToggleService()
}

// MARK: - Actions

private extension Actions {
    struct ToggleFeatureA: Action {}
    struct DidToggleFeatureA: Action {
        let isToggled: Bool
    }

    struct ToggleFeatureB: Action {}
    struct DidToggleFeatureB: Action {
        let isToggled: Bool
    }

    struct SyncFeatureB: Action {}
    struct DidSyncFeatureB: Action {
        let isToggled: Bool
    }
}

// MARK: - Feature A

private struct FeatureAEnvironment: Sendable {
    let service: SharedToggleService
}

private protocol FeatureAEnvironmentProviding {
    static var featureA: FeatureAEnvironment { get }
}

private protocol FeatureA: AppReducer {
    associatedtype Environments: FeatureAEnvironmentProviding

    var featureA: FeatureAState<Self> { get }
}

private struct FeatureAState<State: FeatureA>: FeatureState {
    var form = FeatureAForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        FeatureAMiddleware<State>(
            store: store,
            environment: State.Environments.featureA,
            queue: AppQueues.featureA
        )
    }
}

private struct FeatureAForm: UDF.Form, Equatable {
    var isToggled = false
    var executionCount = 0

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidToggleFeatureA:
            isToggled = action.isToggled
            executionCount += 1

        default:
            break
        }
    }
}

private final class FeatureAMiddleware<State: FeatureA>:
    FeatureMiddleware<State>,
    @unchecked Sendable
{
    typealias Environment = FeatureAEnvironment

    var environment: Environment!

    func reduce(_ action: some Action, for state: State) {
        switch action {
        case is Actions.ToggleFeatureA:
            environment.service.toggle()
            store.dispatch(Actions.DidToggleFeatureA(isToggled: environment.service.isToggled))

        default:
            break
        }
    }
}

// MARK: - Feature B

private struct FeatureBEnvironment: Sendable {
    let service: SharedToggleService
}

private protocol FeatureBEnvironmentProviding {
    static var featureB: FeatureBEnvironment { get }
}

private protocol FeatureB: AppReducer {
    associatedtype Environments: FeatureBEnvironmentProviding

    var featureB: FeatureBState<Self> { get }
}

private struct FeatureBState<State: FeatureB>: FeatureState {
    var form = FeatureBForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        FeatureBMiddleware<State>(
            store: store,
            environment: State.Environments.featureB,
            queue: AppQueues.featureB
        )
    }
}

private struct FeatureBForm: UDF.Form, Equatable {
    var isToggled = false
    var executionCount = 0

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidToggleFeatureB:
            isToggled = action.isToggled
            executionCount += 1

        case let action as Actions.DidSyncFeatureB:
            isToggled = action.isToggled
            executionCount += 1

        default:
            break
        }
    }
}

private final class FeatureBMiddleware<State: FeatureB>:
    FeatureMiddleware<State>,
    @unchecked Sendable
{
    typealias Environment = FeatureBEnvironment

    var environment: Environment!

    func reduce(_ action: some Action, for state: State) {
        switch action {
        case is Actions.ToggleFeatureB:
            environment.service.toggle()
            store.dispatch(Actions.DidToggleFeatureB(isToggled: environment.service.isToggled))

        case is Actions.SyncFeatureB:
            store.dispatch(Actions.DidSyncFeatureB(isToggled: environment.service.isToggled))

        default:
            break
        }
    }
}

// MARK: - Composing App State & Environments

private enum AppEnvironments: FeatureAEnvironmentProviding, FeatureBEnvironmentProviding {
    static var featureA: FeatureAEnvironment {
        FeatureAEnvironment(service: AppServices.service)
    }

    static var featureB: FeatureBEnvironment {
        FeatureBEnvironment(service: AppServices.service)
    }
}

private struct AppState: AppReducer, FeatureA, FeatureB {
    typealias Environments = AppEnvironments

    var featureA = FeatureAState<AppState>()
    var featureB = FeatureBState<AppState>()
}
