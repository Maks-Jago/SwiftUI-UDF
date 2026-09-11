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
        let store = TestStore(initial: RegistrationAppState())
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
        let store = EnvironmentStore(initial: CompositeAppState(), loggers: [])
        let registered = await waitForCondition(timeout: 2) {
            store.state.alpha.form.marker == "alpha"
                && store.state.empty.form.marker == nil
                && store.state.beta.form.marker == "beta"
        }

        #expect(registered)
    }

    @Test("Initial observation receives state after nested InitialSetup")
    func initialObservationReceivesInitializedFeatureState() async {
        let store = EnvironmentStore(initial: CompositeAppState(), loggers: [])

        #expect(store.state.alpha.form.preparedValue == "prepared")

        let observedInitializedState = await waitForCondition(timeout: 2) {
            store.state.alpha.form.observedValue == "prepared"
        }

        #expect(observedInitializedState)
    }

    @Test("TestStore requires explicit feature middleware subscription")
    func testStoreRequiresExplicitFeatureMiddlewareSubscription() async {
        let store = await TestStore(initial: CompositeAppState())

        await store.dispatch(Actions.TriggerAlpha())
        await store.wait()
        #expect(await store.state.alpha.form.marker == nil)

        await store.subscribe(
            AlphaMiddleware.self,
            environment: MarkerEnvironment(marker: "explicit-test-store")
        )
        await store.dispatch(Actions.TriggerAlpha())
        await store.wait()

        #expect(await store.state.alpha.form.marker == "explicit-test-store")
    }

    @Test("Each EnvironmentStore receives a fresh feature middleware instance")
    func eachEnvironmentStoreReceivesFreshMiddleware() async throws {
        let firstStore = EnvironmentStore(initial: CompositeAppState(), loggers: [])
        let firstObserved = await waitForCondition(timeout: 2) {
            firstStore.state.alpha.form.middlewareID != nil
        }
        #expect(firstObserved)
        let firstID = try #require(firstStore.state.alpha.form.middlewareID)

        let secondStore = EnvironmentStore(initial: CompositeAppState(), loggers: [])
        let secondObserved = await waitForCondition(timeout: 2) {
            secondStore.state.alpha.form.middlewareID != nil
        }
        #expect(secondObserved)
        let secondID = try #require(secondStore.state.alpha.form.middlewareID)

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

    struct TriggerAlpha: Action {}

    struct RecordAlpha: Action {
        let marker: String
        let middlewareID: UUID
        let preparedValue: String
    }

    struct RecordBeta: Action {
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
    FeatureMiddleware<State>,
    @unchecked Sendable
{
    typealias Environment = MarkerEnvironment

    var environment: Environment!

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

// MARK: - Composite AppState (Alpha, Empty, Beta Features)

private protocol AlphaEnvironmentProviding {
    static var alpha: MarkerEnvironment { get }
}

private protocol BetaEnvironmentProviding {
    static var beta: MarkerEnvironment { get }
}

private enum CompositeEnvironments: AlphaEnvironmentProviding, BetaEnvironmentProviding {
    static let alpha = MarkerEnvironment(marker: "alpha")
    static let beta = MarkerEnvironment(marker: "beta")
}

private struct CompositeAppState: AppReducer {
    typealias Environments = CompositeEnvironments

    var alpha = AlphaFeatureState<CompositeAppState>()
    var empty = EmptyFeatureState<CompositeAppState>()
    var beta = BetaFeatureState<CompositeAppState>()
}

private struct AlphaFeatureState<State: AppReducer>: FeatureState {
    var form = AlphaForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        AlphaMiddleware<State>(store: store, environment: CompositeEnvironments.alpha)
    }
}

private struct EmptyFeatureState<State: AppReducer>: FeatureState {
    typealias AppState = State
    var form = EmptyRegistrationForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }
}

private struct BetaFeatureState<State: AppReducer>: FeatureState {
    var form = BetaForm()

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
        BetaMiddleware<State>(store: store, environment: CompositeEnvironments.beta)
    }
}

private struct AlphaForm: UDF.Form, InitialSetup, Equatable {
    typealias AppState = CompositeAppState

    var marker: String?
    var middlewareID: UUID?
    var preparedValue = "unprepared"
    var observedValue: String?

    mutating func initialSetup(with state: CompositeAppState) {
        preparedValue = "prepared"
    }

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.RecordAlpha:
            marker = action.marker
            middlewareID = action.middlewareID
            observedValue = action.preparedValue

        default:
            break
        }
    }
}

private struct EmptyRegistrationForm: UDF.Form, Equatable {
    var marker: String?
}

private struct BetaForm: UDF.Form, Equatable {
    var marker: String?

    mutating func reduce(_ action: some Action) {
        if let action = action as? Actions.RecordBeta {
            marker = action.marker
        }
    }
}

private final class AlphaMiddleware<State: AppReducer>: FeatureMiddleware<State>, @unchecked Sendable {
    typealias Environment = MarkerEnvironment

    var environment: Environment!
    private let instanceID = UUID()

    func reduce(_ action: some Action, for state: State) {
        if action is Actions.TriggerAlpha {
            let prepared = (state as? CompositeAppState)?.alpha.form.preparedValue ?? ""
            store.dispatch(Actions.RecordAlpha(
                marker: environment.marker,
                middlewareID: instanceID,
                preparedValue: prepared
            ))
        }
    }

    func observe(state: State) {
        guard let compositeState = state as? CompositeAppState else {
            return
        }

        store.dispatch(Actions.RecordAlpha(
            marker: environment.marker,
            middlewareID: instanceID,
            preparedValue: compositeState.alpha.form.preparedValue
        ))
    }
}

private final class BetaMiddleware<State: AppReducer>: FeatureMiddleware<State>, @unchecked Sendable {
    typealias Environment = MarkerEnvironment

    var environment: Environment!

    func observe(state: State) {
        store.dispatch(Actions.RecordBeta(marker: environment.marker))
    }
}
