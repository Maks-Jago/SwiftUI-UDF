//===--- FeatureMiddlewareRegistrationTests.swift -----------------===//
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
import SwiftUI
import Testing
@testable import UDF
import UDFSwiftTesting

@Suite("Feature middleware registration")
struct FeatureMiddlewareRegistrationTests {
    @TestStoreActor
    @Test("Collection preserves explicit feature instances and legacy type wrappers")
    func collectionPreservesExplicitInstancesAndLegacyTypes() async throws {
        let store = TestStore(
            initial: RegistrationAppState(),
            registerFeatureMiddlewares: false
        )
        var wrappers: [MiddlewareWrapper<RegistrationAppState>] = []

        await store.subscribe { store in
            wrappers = RegistrationFeatureState.registerMiddlewares(in: store)
            return wrappers
        }

        #expect(wrappers.count == 2)

        let featureMiddleware = try #require(
            wrappers[0].instance as? ExplicitRegistrationMiddleware<RegistrationAppState>
        )
        #expect(featureMiddleware.environment.marker == "feature-explicit")
        #expect(
            ObjectIdentifier(wrappers[0].type)
                == ObjectIdentifier(ExplicitRegistrationMiddleware<RegistrationAppState>.self)
        )

        #expect(wrappers[1].instance == nil)
        #expect(
            ObjectIdentifier(wrappers[1].type)
                == ObjectIdentifier(LegacyRegistrationMiddleware<RegistrationAppState>.self)
        )
    }

    @Test("EnvironmentStore automatically resolves every middleware from one feature")
    func environmentStoreRegistersEveryMiddlewareFromOneFeature() async {
        let store = EnvironmentStore(initial: RegistrationAppState(), loggers: [])

        let registered = await waitForCondition(timeout: 2) {
            store.state.registration.form.explicitMarker == "feature-explicit"
                && store.state.registration.form.legacyMarker == "legacy-test"
        }

        #expect(registered)
    }

    @Test("Multiple root features register across an empty feature")
    func multipleRootFeaturesRegisterAcrossEmptyFeature() async {
        let store = EnvironmentStore(initial: FeatureHostAppState(), loggers: [])
        let registered = await waitForCondition(timeout: 2) {
            store.state.firstFeature.form.marker == "first-feature-test"
                && store.state.empty.form.marker == nil
                && store.state.secondFeature.form.marker == "second-feature-test"
        }

        #expect(registered)
    }

    @Test("Initial observation receives state after nested InitialSetup")
    func initialObservationReceivesInitializedFeatureState() async {
        let store = EnvironmentStore(initial: FeatureHostAppState(), loggers: [])

        #expect(store.state.firstFeature.form.preparedValue == "prepared")

        let observedInitializedState = await waitForCondition(timeout: 2) {
            store.state.firstFeature.form.observedValue == "prepared"
        }

        #expect(observedInitializedState)
    }

    @Test("TestStore automatically builds test environments for type-registered feature middleware")
    func testStoreAutomaticallyBuildsFeatureTestEnvironments() async {
        let store = await TestStore(initial: FeatureHostAppState())

        await store.dispatch(Actions.TriggerFirstFeature())
        await store.wait()

        let state = await store.state
        #expect(state.firstFeature.form.marker == "first-feature-test")
        #expect(state.secondFeature.form.marker == "second-feature-test")
    }

    @Test("TestStore allows re-registering and replacing an auto-registered middleware with custom environment")
    func testStoreReplacesAutoRegisteredMiddleware() async {
        let store = await TestStore(initial: FeatureHostAppState())

        let automaticallyRegistered = await waitForCondition(timeout: 2) {
            let state = await store.state
            return state.firstFeature.form.marker == "first-feature-test"
                && state.secondFeature.form.marker == "second-feature-test"
        }
        #expect(automaticallyRegistered)

        await store.subscribe(
            FirstFeatureMiddleware<FeatureHostAppState>.self,
            environment: MarkerEnvironment(marker: "first-feature-custom-override")
        )

        let replacementRegistered = await waitForCondition(timeout: 2) {
            await store.state.firstFeature.form.marker == "first-feature-custom-override"
        }
        #expect(replacementRegistered)

        await store.dispatch(Actions.ResetFirstFeatureMiddlewareRuns())
        await store.wait()

        await store.dispatch(Actions.TriggerFirstFeature())
        await store.wait()

        let state = await store.state
        #expect(state.firstFeature.form.marker == "first-feature-custom-override")
        #expect(state.firstFeature.form.handledMarkers == ["first-feature-custom-override"])
        #expect(state.secondFeature.form.marker == "second-feature-test")
    }

    @Test("EnvironmentStore allows re-registering and replacing an auto-registered middleware with custom environment")
    func environmentStoreReplacesAutoRegisteredMiddleware() async {
        let store = EnvironmentStore(initial: FeatureHostAppState(), loggers: [])

        let automaticallyRegistered = await waitForCondition(timeout: 2) {
            store.state.firstFeature.form.marker == "first-feature-test"
                && store.state.secondFeature.form.marker == "second-feature-test"
        }
        #expect(automaticallyRegistered)

        store.subscribe(
            FirstFeatureMiddleware<FeatureHostAppState>.self,
            environment: MarkerEnvironment(marker: "first-feature-custom-override")
        )

        let replacementRegistered = await waitForCondition(timeout: 2) {
            store.state.firstFeature.form.marker == "first-feature-custom-override"
        }
        #expect(replacementRegistered)

        store.dispatch(Actions.ResetFirstFeatureMiddlewareRuns())
        let recordsReset = await waitForCondition(timeout: 2) {
            store.state.firstFeature.form.handledMarkers.isEmpty
        }
        #expect(recordsReset)

        store.dispatch(Actions.TriggerFirstFeature())
        let replacementHandledAction = await waitForCondition(timeout: 2) {
            !store.state.firstFeature.form.handledMarkers.isEmpty
        }
        #expect(replacementHandledAction)

        let duplicateHandledAction = await waitForCondition(timeout: 0.2) {
            store.state.firstFeature.form.handledMarkers.count > 1
        }
        #expect(!duplicateHandledAction)
        #expect(store.state.firstFeature.form.marker == "first-feature-custom-override")
        #expect(store.state.firstFeature.form.handledMarkers == ["first-feature-custom-override"])
        #expect(store.state.secondFeature.form.marker == "second-feature-test")
    }

    @Test("Feature live environment builders forward to the app environment namespace")
    func liveEnvironmentBuildersForwardToAppEnvironments() {
        let store = InternalStore(initial: FeatureHostAppState(), loggers: [])

        let firstFeatureEnvironment = FirstFeatureMiddleware<FeatureHostAppState>.buildLiveEnvironment(for: store)
        let secondFeatureEnvironment = SecondFeatureMiddleware<FeatureHostAppState>.buildLiveEnvironment(for: store)

        #expect(firstFeatureEnvironment.marker == "first-feature")
        #expect(secondFeatureEnvironment.marker == "second-feature")
    }

    @Test("Each EnvironmentStore receives a fresh feature middleware instance")
    func eachEnvironmentStoreReceivesFreshMiddleware() async throws {
        let firstStore = EnvironmentStore(initial: FeatureHostAppState(), loggers: [])
        let firstObserved = await waitForCondition(timeout: 2) {
            firstStore.state.firstFeature.form.middlewareID != nil
        }
        #expect(firstObserved)
        let firstID = try #require(firstStore.state.firstFeature.form.middlewareID)

        let secondStore = EnvironmentStore(initial: FeatureHostAppState(), loggers: [])
        let secondObserved = await waitForCondition(timeout: 2) {
            secondStore.state.firstFeature.form.middlewareID != nil
        }
        #expect(secondObserved)
        let secondID = try #require(secondStore.state.firstFeature.form.middlewareID)

        #expect(firstID != secondID)
    }
}

// MARK: - Actions

private extension Actions {
    struct RecordExplicitRegistration: Action {
        let marker: String
    }

    struct RecordLegacyRegistration: Action {
        let marker: String
    }

    struct TriggerFirstFeature: Action {}

    struct ResetFirstFeatureMiddlewareRuns: Action {}

    struct RecordFirstFeatureMiddlewareRun: Action {
        let marker: String
        let middlewareID: UUID
        let preparedValue: String
    }

    struct RecordSecondFeatureMiddlewareRun: Action {
        let marker: String
    }
}

// MARK: - Feature with Multiple Middlewares (Explicit + Legacy)

private struct MarkerEnvironment: Sendable {
    let marker: String
}

private protocol RegistrationEnvironmentProviding {
    static var explicit: MarkerEnvironment { get }
}

private protocol RegistrationFeatureHost: AppReducer {
    associatedtype Environments: RegistrationEnvironmentProviding

    var registration: RegistrationFeatureState<Self> { get }
}

private enum RegistrationEnvironments: RegistrationEnvironmentProviding {
    static let explicit = MarkerEnvironment(marker: "feature-explicit")
}

private struct RegistrationAppState: AppReducer, RegistrationFeatureHost {
    typealias Environments = RegistrationEnvironments

    var registration = RegistrationFeatureState<RegistrationAppState>()
}

private struct RegistrationFeatureState<State: RegistrationFeatureHost>: FeatureState {
    var form = RegistrationForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        ExplicitRegistrationMiddleware<State>(
            store: store,
            environment: State.Environments.explicit
        )
        LegacyRegistrationMiddleware<State>.self
    }
}

private struct RegistrationForm: UDF.Form, Equatable {
    var explicitMarker: String?
    var legacyMarker: String?

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.RecordExplicitRegistration:
            explicitMarker = action.marker

        case let action as Actions.RecordLegacyRegistration:
            legacyMarker = action.marker

        default:
            break
        }
    }
}

private final class ExplicitRegistrationMiddleware<State: RegistrationFeatureHost>:
    Middleware<State>,
    @unchecked Sendable
{
    typealias Environment = MarkerEnvironment

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        State.Environments.explicit
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        MarkerEnvironment(marker: "explicit-test")
    }

    func observe(state: State) {
        store.dispatch(Actions.RecordExplicitRegistration(marker: environment.marker))
    }
}

private final class LegacyRegistrationMiddleware<State: RegistrationFeatureHost>:
    Middleware<State>,
    @unchecked Sendable
{
    struct Environment: Sendable {
        let marker: String
    }

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        Environment(marker: "legacy-test")
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        Environment(marker: "legacy-test")
    }

    func observe(state: State) {
        store.dispatch(Actions.RecordLegacyRegistration(marker: environment.marker))
    }
}

// MARK: - Feature Host AppState

private protocol FirstFeatureEnvironmentProviding {
    static var firstFeature: MarkerEnvironment { get }
}

private protocol SecondFeatureEnvironmentProviding {
    static var secondFeature: MarkerEnvironment { get }
}

private enum FeatureHostEnvironments: FirstFeatureEnvironmentProviding, SecondFeatureEnvironmentProviding {
    static let firstFeature = MarkerEnvironment(marker: "first-feature")
    static let secondFeature = MarkerEnvironment(marker: "second-feature")
}

private struct FeatureHostAppState: AppReducer {
    typealias Environments = FeatureHostEnvironments

    var firstFeature = FirstFeatureState<FeatureHostAppState>()
    var empty = EmptyFeatureState<FeatureHostAppState>()
    var secondFeature = SecondFeatureState<FeatureHostAppState>()
}

private struct FirstFeatureState<State: AppReducer>: FeatureState {
    var form = FirstFeatureForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        FirstFeatureMiddleware<State>.self
    }
}

private struct EmptyFeatureState<State: AppReducer>: FeatureState {
    typealias AppState = State
    var form = EmptyRegistrationForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }
}

private struct SecondFeatureState<State: AppReducer>: FeatureState {
    var form = SecondFeatureForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        SecondFeatureMiddleware<State>.self
    }
}

private struct FirstFeatureForm: UDF.Form, InitialSetup, Equatable {
    typealias AppState = FeatureHostAppState

    var marker: String?
    var handledMarkers: [String] = []
    var middlewareID: UUID?
    var preparedValue = "unprepared"
    var observedValue: String?

    mutating func initialSetup(with state: FeatureHostAppState) {
        preparedValue = "prepared"
    }

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.RecordFirstFeatureMiddlewareRun:
            marker = action.marker
            handledMarkers.append(action.marker)
            middlewareID = action.middlewareID
            observedValue = action.preparedValue

        case is Actions.ResetFirstFeatureMiddlewareRuns:
            handledMarkers = []

        default:
            break
        }
    }
}

private struct EmptyRegistrationForm: UDF.Form, Equatable {
    var marker: String?
}

private struct SecondFeatureForm: UDF.Form, Equatable {
    var marker: String?

    mutating func reduce(_ action: some Action) {
        if let action = action as? Actions.RecordSecondFeatureMiddlewareRun {
            marker = action.marker
        }
    }
}

private final class FirstFeatureMiddleware<State: AppReducer>: Middleware<State>, @unchecked Sendable {
    typealias Environment = MarkerEnvironment

    var environment: Environment!
    private let instanceID = UUID()

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        FeatureHostEnvironments.firstFeature
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        MarkerEnvironment(marker: "first-feature-test")
    }

    func reduce(_ action: some Action, for state: State) {
        if action is Actions.TriggerFirstFeature {
            let prepared = (state as? FeatureHostAppState)?.firstFeature.form.preparedValue ?? ""
            store.dispatch(Actions.RecordFirstFeatureMiddlewareRun(
                marker: environment.marker,
                middlewareID: instanceID,
                preparedValue: prepared
            ))
        }
    }

    func observe(state: State) {
        guard let featureHostState = state as? FeatureHostAppState else {
            return
        }

        store.dispatch(Actions.RecordFirstFeatureMiddlewareRun(
            marker: environment.marker,
            middlewareID: instanceID,
            preparedValue: featureHostState.firstFeature.form.preparedValue
        ))
    }
}

private final class SecondFeatureMiddleware<State: AppReducer>: Middleware<State>, @unchecked Sendable {
    typealias Environment = MarkerEnvironment

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        FeatureHostEnvironments.secondFeature
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        MarkerEnvironment(marker: "second-feature-test")
    }

    func observe(state: State) {
        store.dispatch(Actions.RecordSecondFeatureMiddlewareRun(marker: environment.marker))
    }
}
