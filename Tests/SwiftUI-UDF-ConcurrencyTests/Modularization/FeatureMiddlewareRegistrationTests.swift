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

    @Test("TestStore leaves feature middleware unregistered until explicitly subscribed")
    func testStoreDoesNotAutomaticallyRegisterFeatureMiddleware() async {
        let store = await TestStore(initial: RegistrationHostState())

        await store.dispatch(Actions.InvokeReplaceableFeatureMiddleware())
        await store.wait()

        let state = await store.state
        #expect(state.replaceableFeature.form.marker == nil)
        #expect(state.replaceableFeature.form.handledMarkers.isEmpty)
        #expect(state.companionFeature.form.marker == nil)
        #expect(state.replaceableFeature.form.preparedValue == "prepared")
    }

    @Test("TestStore builds test environments for explicitly subscribed middleware types")
    func testStoreBuildsExplicitMiddlewareTestEnvironments() async {
        let store = await TestStore(initial: RegistrationHostState())
        await store.subscribe { _ -> [MiddlewareWrapper<RegistrationHostState>] in
            ReplaceableFeatureMiddleware<RegistrationHostState>.self
            CompanionFeatureMiddleware<RegistrationHostState>.self
        }
        let subscribed = await waitForCondition(timeout: 2) {
            let state = await store.state
            return state.replaceableFeature.form.marker == "replaceable-feature-test"
                && state.companionFeature.form.marker == "companion-feature-test"
        }
        #expect(subscribed)
        await store.wait()

        let state = await store.state
        #expect(state.replaceableFeature.form.marker == "replaceable-feature-test")
        #expect(state.companionFeature.form.marker == "companion-feature-test")
    }

    @Test("TestStore subscribes only the selected middleware with its custom environment")
    func testStoreRegistersSelectedMiddlewareWithCustomEnvironment() async {
        let store = await TestStore(initial: RegistrationHostState())
        await store.subscribe(
            ReplaceableFeatureMiddleware<RegistrationHostState>.self,
            environment: MarkerEnvironment(marker: "custom-test-environment")
        )
        let subscribed = await waitForCondition(timeout: 2) {
            await store.state.replaceableFeature.form.marker == "custom-test-environment"
        }
        #expect(subscribed)
        await store.wait()

        await store.dispatch(Actions.ResetReplaceableMiddlewareRuns())
        await store.wait()
        await store.dispatch(Actions.InvokeReplaceableFeatureMiddleware())
        await store.wait()

        let state = await store.state
        #expect(state.replaceableFeature.form.handledMarkers == ["custom-test-environment"])
        #expect(state.companionFeature.form.marker == nil)
    }

    #if os(macOS) && DEBUG
        @Test("EnvironmentStore traps when an automatically registered middleware is subscribed again")
        func environmentStoreRejectsDuplicateMiddlewareInDebug() async throws {
            let result = try await #require(
                processExitsWith: .failure,
                observing: [\.standardErrorContent]
            ) {
                let store = EnvironmentStore(initial: RegistrationAppState(), loggers: [])
                store.subscribe(
                    ExplicitRegistrationMiddleware<RegistrationAppState>.self,
                    environment: MarkerEnvironment(marker: "duplicate")
                )
            }

            let standardError = String(decoding: result.standardErrorContent, as: UTF8.self)
            #expect(standardError.contains("ExplicitRegistrationMiddleware"))
            #expect(standardError.contains("is already registered"))
        }

        @Test("TestStore traps when a middleware type is explicitly subscribed twice in one batch")
        func testStoreRejectsDuplicateMiddlewareInDebug() async throws {
            let result = try await #require(
                processExitsWith: .failure,
                observing: [\.standardErrorContent]
            ) {
                let store = await TestStore(initial: RegistrationAppState())
                await store.subscribe { _ -> [MiddlewareWrapper<RegistrationAppState>] in
                    LegacyRegistrationMiddleware<RegistrationAppState>.self
                    LegacyRegistrationMiddleware<RegistrationAppState>.self
                }
            }

            let standardError = String(decoding: result.standardErrorContent, as: UTF8.self)
            #expect(standardError.contains("LegacyRegistrationMiddleware"))
            #expect(standardError.contains("is already registered"))
        }
    #endif

    #if !DEBUG
        @Test("EnvironmentStore retains both registrations of the same middleware type in release")
        func environmentStoreAllowsDuplicateMiddlewareInRelease() async {
            let store = EnvironmentStore(initial: RegistrationHostState(), loggers: [])
            store.subscribe(
                ReplaceableFeatureMiddleware<RegistrationHostState>.self,
                environment: MarkerEnvironment(marker: "custom-test-environment")
            )

            let initiallyObserved = await waitForCondition(timeout: 2) {
                store.state.replaceableFeature.form.handledMarkers.count == 2
            }
            #expect(initiallyObserved)

            store.dispatch(Actions.ResetReplaceableMiddlewareRuns())
            let recordsReset = await waitForCondition(timeout: 2) {
                store.state.replaceableFeature.form.handledMarkers.isEmpty
            }
            #expect(recordsReset)

            store.dispatch(Actions.InvokeReplaceableFeatureMiddleware())
            let bothHandledAction = await waitForCondition(timeout: 2) {
                store.state.replaceableFeature.form.handledMarkers.count == 2
            }
            #expect(bothHandledAction)
            #expect(store.state.replaceableFeature.form.handledMarkers.sorted() == [
                "custom-test-environment",
                "replaceable-feature-test",
            ])
        }

        @Test("TestStore retains both explicitly subscribed middleware instances in release")
        func testStoreAllowsDuplicateMiddlewareInRelease() async {
            let store = await TestStore(initial: RegistrationHostState())
            await store.subscribe(
                ReplaceableFeatureMiddleware<RegistrationHostState>.self,
                environment: MarkerEnvironment(marker: "first-test-environment")
            )
            await store.subscribe(
                ReplaceableFeatureMiddleware<RegistrationHostState>.self,
                environment: MarkerEnvironment(marker: "second-test-environment")
            )
            let initiallyObserved = await waitForCondition(timeout: 2) {
                await store.state.replaceableFeature.form.handledMarkers.count == 2
            }
            #expect(initiallyObserved)
            await store.wait()

            await store.dispatch(Actions.ResetReplaceableMiddlewareRuns())
            await store.wait()
            await store.dispatch(Actions.InvokeReplaceableFeatureMiddleware())
            await store.wait()

            let state = await store.state
            #expect(state.replaceableFeature.form.handledMarkers.sorted() == [
                "first-test-environment",
                "second-test-environment",
            ])
        }
    #endif

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
    typealias FeatureRouting = EmptyRouting

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
    typealias FeatureRouting = EmptyRouting

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
    typealias FeatureRouting = EmptyRouting

    var form = EmptyRegistrationForm()

    static func registerMiddlewares(in store: any Store<State>) -> [MiddlewareWrapper<State>] {
    }

    static func entryPoint(input: Void) -> some View {
        EmptyView()
    }
}

private struct CompanionFeatureState<State: AppReducer>: FeatureState {
    typealias FeatureRouting = EmptyRouting

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
