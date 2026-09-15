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
        let store = EnvironmentStore(initial: RegistrationHostState(), loggers: [])
        let registered = await waitForCondition(timeout: 2) {
            store.state.replaceableFeature.form.marker == "replaceable-feature-test"
                && store.state.empty.form.marker == nil
                && store.state.companionFeature.form.marker == "companion-feature-test"
        }

        #expect(registered)
    }

    @Test("Initial observation receives state after nested InitialSetup")
    func initialObservationReceivesInitializedFeatureState() async {
        let store = EnvironmentStore(initial: RegistrationHostState(), loggers: [])

        #expect(store.state.replaceableFeature.form.preparedValue == "prepared")

        let observedInitializedState = await waitForCondition(timeout: 2) {
            store.state.replaceableFeature.form.observedValue == "prepared"
        }

        #expect(observedInitializedState)
    }

    @Test("TestStore automatically builds test environments for type-registered feature middleware")
    func storeAutomaticallyBuildsFeatureTestEnvironments() async {
        let store = await TestStore(initial: RegistrationHostState())

        await store.dispatch(Actions.InvokeReplaceableFeatureMiddleware())
        await store.wait()

        let state = await store.state
        #expect(state.replaceableFeature.form.marker == "replaceable-feature-test")
        #expect(state.companionFeature.form.marker == "companion-feature-test")
    }

    @Test("TestStore allows re-registering and replacing an auto-registered middleware with custom environment")
    func storeReplacesAutoRegisteredMiddleware() async {
        let store = await TestStore(initial: RegistrationHostState())

        let automaticallyRegistered = await waitForCondition(timeout: 2) {
            let state = await store.state
            return state.replaceableFeature.form.marker == "replaceable-feature-test"
                && state.companionFeature.form.marker == "companion-feature-test"
        }
        #expect(automaticallyRegistered)

        await store.subscribe(
            ReplaceableFeatureMiddleware<RegistrationHostState>.self,
            environment: MarkerEnvironment(marker: "replaceable-feature-custom-override")
        )

        let replacementRegistered = await waitForCondition(timeout: 2) {
            await store.state.replaceableFeature.form.marker == "replaceable-feature-custom-override"
        }
        #expect(replacementRegistered)

        await store.dispatch(Actions.ResetReplaceableMiddlewareRuns())
        await store.wait()

        await store.dispatch(Actions.InvokeReplaceableFeatureMiddleware())
        await store.wait()

        let state = await store.state
        #expect(state.replaceableFeature.form.marker == "replaceable-feature-custom-override")
        #expect(state.replaceableFeature.form.handledMarkers == ["replaceable-feature-custom-override"])
        #expect(state.companionFeature.form.marker == "companion-feature-test")
    }

    @Test("EnvironmentStore allows re-registering and replacing an auto-registered middleware with custom environment")
    func environmentStoreReplacesAutoRegisteredMiddleware() async {
        let store = EnvironmentStore(initial: RegistrationHostState(), loggers: [])

        let automaticallyRegistered = await waitForCondition(timeout: 2) {
            store.state.replaceableFeature.form.marker == "replaceable-feature-test"
                && store.state.companionFeature.form.marker == "companion-feature-test"
        }
        #expect(automaticallyRegistered)

        store.subscribe(
            ReplaceableFeatureMiddleware<RegistrationHostState>.self,
            environment: MarkerEnvironment(marker: "replaceable-feature-custom-override")
        )

        let replacementRegistered = await waitForCondition(timeout: 2) {
            store.state.replaceableFeature.form.marker == "replaceable-feature-custom-override"
        }
        #expect(replacementRegistered)

        store.dispatch(Actions.ResetReplaceableMiddlewareRuns())
        let recordsReset = await waitForCondition(timeout: 2) {
            store.state.replaceableFeature.form.handledMarkers.isEmpty
        }
        #expect(recordsReset)

        store.dispatch(Actions.InvokeReplaceableFeatureMiddleware())
        let replacementHandledAction = await waitForCondition(timeout: 2) {
            !store.state.replaceableFeature.form.handledMarkers.isEmpty
        }
        #expect(replacementHandledAction)

        let duplicateHandledAction = await waitForCondition(timeout: 0.2) {
            store.state.replaceableFeature.form.handledMarkers.count > 1
        }
        #expect(!duplicateHandledAction)
        #expect(store.state.replaceableFeature.form.marker == "replaceable-feature-custom-override")
        #expect(store.state.replaceableFeature.form.handledMarkers == ["replaceable-feature-custom-override"])
        #expect(store.state.companionFeature.form.marker == "companion-feature-test")
    }

    @Test("Feature live environment builders forward to the app environment namespace")
    func liveEnvironmentBuildersForwardToAppEnvironments() {
        let store = InternalStore(initial: RegistrationHostState(), loggers: [])

        let replaceableEnvironment = ReplaceableFeatureMiddleware<RegistrationHostState>.buildLiveEnvironment(for: store)
        let companionEnvironment = CompanionFeatureMiddleware<RegistrationHostState>.buildLiveEnvironment(for: store)

        #expect(replaceableEnvironment.marker == "replaceable-feature")
        #expect(companionEnvironment.marker == "companion-feature")
    }

    @Test("Each EnvironmentStore receives a fresh feature middleware instance")
    func eachEnvironmentStoreReceivesFreshMiddleware() async throws {
        let firstStore = EnvironmentStore(initial: RegistrationHostState(), loggers: [])
        let firstObserved = await waitForCondition(timeout: 2) {
            firstStore.state.replaceableFeature.form.middlewareID != nil
        }
        #expect(firstObserved)
        let firstID = try #require(firstStore.state.replaceableFeature.form.middlewareID)

        let secondStore = EnvironmentStore(initial: RegistrationHostState(), loggers: [])
        let secondObserved = await waitForCondition(timeout: 2) {
            secondStore.state.replaceableFeature.form.middlewareID != nil
        }
        #expect(secondObserved)
        let secondID = try #require(secondStore.state.replaceableFeature.form.middlewareID)

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

    struct InvokeReplaceableFeatureMiddleware: Action {}

    struct ResetReplaceableMiddlewareRuns: Action {}

    struct RecordReplaceableMiddlewareRun: Action {
        let marker: String
        let middlewareID: UUID
        let preparedValue: String
    }

    struct RecordCompanionMiddlewareRun: Action {
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

private protocol ReplaceableFeatureEnvironmentProviding {
    static var replaceableFeature: MarkerEnvironment { get }
}

private protocol CompanionFeatureEnvironmentProviding {
    static var companionFeature: MarkerEnvironment { get }
}

private enum RegistrationHostEnvironments: ReplaceableFeatureEnvironmentProviding, CompanionFeatureEnvironmentProviding {
    static let replaceableFeature = MarkerEnvironment(marker: "replaceable-feature")
    static let companionFeature = MarkerEnvironment(marker: "companion-feature")
}

private struct RegistrationHostState: AppReducer {
    typealias Environments = RegistrationHostEnvironments

    var replaceableFeature = ReplaceableFeatureState<RegistrationHostState>()
    var empty = EmptyFeatureState<RegistrationHostState>()
    var companionFeature = CompanionFeatureState<RegistrationHostState>()
}

private struct ReplaceableFeatureState<State: AppReducer>: FeatureState {
    var form = ReplaceableFeatureForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        ReplaceableFeatureMiddleware<State>.self
    }
}

private struct EmptyFeatureState<State: AppReducer>: FeatureState {
    typealias AppState = State
    var form = EmptyRegistrationForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }
}

private struct CompanionFeatureState<State: AppReducer>: FeatureState {
    var form = CompanionFeatureForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        CompanionFeatureMiddleware<State>.self
    }
}

private struct ReplaceableFeatureForm: UDF.Form, InitialSetup, Equatable {
    typealias AppState = RegistrationHostState

    var marker: String?
    var handledMarkers: [String] = []
    var middlewareID: UUID?
    var preparedValue = "unprepared"
    var observedValue: String?

    mutating func initialSetup(with state: RegistrationHostState) {
        preparedValue = "prepared"
    }

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.RecordReplaceableMiddlewareRun:
            marker = action.marker
            handledMarkers.append(action.marker)
            middlewareID = action.middlewareID
            observedValue = action.preparedValue

        case is Actions.ResetReplaceableMiddlewareRuns:
            handledMarkers = []

        default:
            break
        }
    }
}

private struct EmptyRegistrationForm: UDF.Form, Equatable {
    var marker: String?
}

private struct CompanionFeatureForm: UDF.Form, Equatable {
    var marker: String?

    mutating func reduce(_ action: some Action) {
        if let action = action as? Actions.RecordCompanionMiddlewareRun {
            marker = action.marker
        }
    }
}

private final class ReplaceableFeatureMiddleware<State: AppReducer>: Middleware<State>, @unchecked Sendable {
    typealias Environment = MarkerEnvironment

    var environment: Environment!
    private let instanceID = UUID()

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        RegistrationHostEnvironments.replaceableFeature
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        MarkerEnvironment(marker: "replaceable-feature-test")
    }

    func reduce(_ action: some Action, for state: State) {
        if action is Actions.InvokeReplaceableFeatureMiddleware {
            let prepared = (state as? RegistrationHostState)?.replaceableFeature.form.preparedValue ?? ""
            store.dispatch(Actions.RecordReplaceableMiddlewareRun(
                marker: environment.marker,
                middlewareID: instanceID,
                preparedValue: prepared
            ))
        }
    }

    func observe(state: State) {
        guard let registrationHostState = state as? RegistrationHostState else {
            return
        }

        store.dispatch(Actions.RecordReplaceableMiddlewareRun(
            marker: environment.marker,
            middlewareID: instanceID,
            preparedValue: registrationHostState.replaceableFeature.form.preparedValue
        ))
    }
}

private final class CompanionFeatureMiddleware<State: AppReducer>: Middleware<State>, @unchecked Sendable {
    typealias Environment = MarkerEnvironment

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        RegistrationHostEnvironments.companionFeature
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        MarkerEnvironment(marker: "companion-feature-test")
    }

    func observe(state: State) {
        store.dispatch(Actions.RecordCompanionMiddlewareRun(marker: environment.marker))
    }
}
