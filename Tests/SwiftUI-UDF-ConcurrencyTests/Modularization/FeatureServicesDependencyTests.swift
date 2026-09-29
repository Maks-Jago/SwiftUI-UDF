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
    func appServicesInjectsSameSingletonAcrossFeatures() async {
        let service = SharedSwitchService()

        await AppServicesContext.$service.withValue(service) {
            let store = TestStore(
                initial: AppState(),
                registerFeatureMiddlewares: false
            )
            var wrappers: [MiddlewareWrapper<AppState>] = []

            await store.subscribe { store in
                wrappers = SwitchControlFeatureState<AppState>.registerMiddlewares(in: store)
                    + SwitchStatusFeatureState<AppState>.registerMiddlewares(in: store)
                return wrappers
            }

            #expect(wrappers.count == 2)

            guard let controlMiddleware = wrappers.compactMap({
                $0.instance as? SwitchControlMiddleware<AppState>
            }).first,
                let statusMiddleware = wrappers.compactMap({
                    $0.instance as? SwitchStatusMiddleware<AppState>
                }).first
            else {
                Issue.record("Expected both middlewares to be present")
                return
            }

            #expect(controlMiddleware.environment.service === service)
            #expect(statusMiddleware.environment.service === service)
            #expect(controlMiddleware.environment.service === statusMiddleware.environment.service)
        }
    }

    @Test("Cross-feature coordination via shared service reflects in EnvironmentStore state")
    func crossFeatureServiceCoordinationInEnvironmentStore() async {
        let service = SharedSwitchService()

        await AppServicesContext.$service.withValue(service) {
            let store = EnvironmentStore(
                initial: AppState(),
                loggers: []
            )

            // 1. The control feature toggles the shared service on
            store.dispatch(Actions.ToggleSwitchControl())

            let controlToggled = await waitForCondition(timeout: 2) {
                store.state.switchControl.form.isToggled == true
                    && service.isToggled == true
            }
            #expect(controlToggled)

            // 2. The status feature syncs with the shared service and observes the change
            store.dispatch(Actions.SyncSwitchStatus())

            let statusSynced = await waitForCondition(timeout: 2) {
                store.state.switchStatus.form.isToggled == true
            }
            #expect(statusSynced)

            // 3. The control feature toggles the shared service off
            store.dispatch(Actions.ToggleSwitchControl())

            let controlToggledOff = await waitForCondition(timeout: 2) {
                store.state.switchControl.form.isToggled == false
                    && service.isToggled == false
            }
            #expect(controlToggledOff)

            // 4. The status feature syncs again and observes it is now off
            store.dispatch(Actions.SyncSwitchStatus())

            let statusSyncedOff = await waitForCondition(timeout: 2) {
                store.state.switchStatus.form.isToggled == false
            }
            #expect(statusSyncedOff)
        }
    }

    @Test("Concurrent calls on shared service from different middleware queues maintain consistency")
    func concurrentSharedServiceAccess() async {
        let service = SharedSwitchService()
        let store = await TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )

        await store.subscribe(build: { store in
            SwitchControlMiddleware<AppState>(
                store: store,
                environment: SwitchControlEnvironment(service: service),
                queue: DispatchQueue(label: "test.switch-control.queue", attributes: .concurrent)
            )
            SwitchStatusMiddleware<AppState>(
                store: store,
                environment: SwitchStatusEnvironment(service: service),
                queue: DispatchQueue(label: "test.switch-status.queue", attributes: .concurrent)
            )
        })

        // Concurrently dispatch actions to both features
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await store.dispatch(Actions.ToggleSwitchControl())
            }
            group.addTask {
                await store.dispatch(Actions.ToggleSwitchStatus())
            }
        }

        await store.wait()

        let state = await store.state
        #expect(state.switchControl.form.executionCount == 1)
        #expect(state.switchStatus.form.executionCount == 1)
        // Two toggles on an initially false boolean returns false
        #expect(service.isToggled == false)
    }

    @Test("Separate store instances share AppServices but maintain isolated middleware instances")
    func separateStoresShareServicesButIsolateMiddlewares() async {
        let service = SharedSwitchService()

        await AppServicesContext.$service.withValue(service) {
            let firstStore = EnvironmentStore(initial: AppState(), loggers: [])
            let secondStore = EnvironmentStore(initial: AppState(), loggers: [])

            firstStore.dispatch(Actions.ToggleSwitchControl())

            let firstToggled = await waitForCondition(timeout: 2) {
                firstStore.state.switchControl.form.isToggled == true
            }
            #expect(firstToggled)

            // Second store's state is independent and isolated
            #expect(secondStore.state.switchControl.form.isToggled == false)

            // But the underlying AppServices service was invoked by store 1
            #expect(service.isToggled == true)

            // Cleanup / Toggle back
            firstStore.dispatch(Actions.ToggleSwitchControl())
            let cleaned = await waitForCondition(timeout: 2) {
                service.isToggled == false
            }
            #expect(cleaned)
        }
    }
}

// MARK: - AppServices & AppQueues Definitions

private enum AppServicesContext {
    @TaskLocal static var service: SharedSwitchService?
}

private enum AppQueues {
    static let switchControl = DispatchQueue(label: "app.switch-control.queue")
    static let switchStatus = DispatchQueue(label: "app.switch-status.queue")
}

private final class SharedSwitchService: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: false)

    var isToggled: Bool {
        lock.withLock { $0 }
    }

    func toggle() {
        lock.withLock { $0.toggle() }
    }
}

private enum AppServices {
    static var service: SharedSwitchService {
        AppServicesContext.service ?? defaultService
    }
    private static let defaultService = SharedSwitchService()
}

// MARK: - Actions

private extension Actions {
    struct ToggleSwitchControl: Action {}
    struct DidToggleSwitchControl: Action {
        let isToggled: Bool
    }

    struct ToggleSwitchStatus: Action {}
    struct DidToggleSwitchStatus: Action {
        let isToggled: Bool
    }

    struct SyncSwitchStatus: Action {}
    struct DidSyncSwitchStatus: Action {
        let isToggled: Bool
    }
}

// MARK: - Switch Control Feature

private struct SwitchControlEnvironment: Sendable {
    let service: SharedSwitchService
}

private protocol SwitchControlEnvironmentProviding {
    static var switchControl: SwitchControlEnvironment { get }
}

private protocol SwitchControlFeature: AppReducer {
    associatedtype Environments: SwitchControlEnvironmentProviding

    var switchControl: SwitchControlFeatureState<Self> { get }
}

private struct SwitchControlFeatureState<State: SwitchControlFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting

    var form = SwitchControlForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        SwitchControlMiddleware<State>(
            store: store,
            environment: State.Environments.switchControl,
            queue: AppQueues.switchControl
        )
    }
}

private struct SwitchControlForm: UDF.Form, Equatable {
    var isToggled = false
    var executionCount = 0

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidToggleSwitchControl:
            isToggled = action.isToggled
            executionCount += 1

        default:
            break
        }
    }
}

private final class SwitchControlMiddleware<State: SwitchControlFeature>:
    Middleware<State>,
    @unchecked Sendable
{
    typealias Environment = SwitchControlEnvironment

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        State.Environments.switchControl
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        State.Environments.switchControl
    }

    func reduce(_ action: some Action, for state: State) {
        switch action {
        case is Actions.ToggleSwitchControl:
            environment.service.toggle()
            store.dispatch(Actions.DidToggleSwitchControl(isToggled: environment.service.isToggled))

        default:
            break
        }
    }
}

// MARK: - Switch Status Feature

private struct SwitchStatusEnvironment: Sendable {
    let service: SharedSwitchService
}

private protocol SwitchStatusEnvironmentProviding {
    static var switchStatus: SwitchStatusEnvironment { get }
}

private protocol SwitchStatusFeature: AppReducer {
    associatedtype Environments: SwitchStatusEnvironmentProviding

    var switchStatus: SwitchStatusFeatureState<Self> { get }
}

private struct SwitchStatusFeatureState<State: SwitchStatusFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting

    var form = SwitchStatusForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        SwitchStatusMiddleware<State>(
            store: store,
            environment: State.Environments.switchStatus,
            queue: AppQueues.switchStatus
        )
    }
}

private struct SwitchStatusForm: UDF.Form, Equatable {
    var isToggled = false
    var executionCount = 0

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidToggleSwitchStatus:
            isToggled = action.isToggled
            executionCount += 1

        case let action as Actions.DidSyncSwitchStatus:
            isToggled = action.isToggled
            executionCount += 1

        default:
            break
        }
    }
}

private final class SwitchStatusMiddleware<State: SwitchStatusFeature>:
    Middleware<State>,
    @unchecked Sendable
{
    typealias Environment = SwitchStatusEnvironment

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        State.Environments.switchStatus
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        State.Environments.switchStatus
    }

    func reduce(_ action: some Action, for state: State) {
        switch action {
        case is Actions.ToggleSwitchStatus:
            environment.service.toggle()
            store.dispatch(Actions.DidToggleSwitchStatus(isToggled: environment.service.isToggled))

        case is Actions.SyncSwitchStatus:
            store.dispatch(Actions.DidSyncSwitchStatus(isToggled: environment.service.isToggled))

        default:
            break
        }
    }
}

// MARK: - Composing App State & Environments

private enum AppEnvironments: SwitchControlEnvironmentProviding, SwitchStatusEnvironmentProviding {
    static var switchControl: SwitchControlEnvironment {
        SwitchControlEnvironment(service: AppServices.service)
    }

    static var switchStatus: SwitchStatusEnvironment {
        SwitchStatusEnvironment(service: AppServices.service)
    }
}

private struct AppState: AppReducer, SwitchControlFeature, SwitchStatusFeature {
    typealias Environments = AppEnvironments

    var switchControl = SwitchControlFeatureState<AppState>()
    var switchStatus = SwitchStatusFeatureState<AppState>()
}
