import SwiftUI
import Testing
@testable import UDF
import UDFSwiftTesting

struct FeatureStateCompositionTests {
    @TestStoreActor
    @Test("FeatureState forwards its entry payload and explicitly registers no middleware")
    func entryPointAndEmptyRegistration() async {
        let input = EntryInput(id: 42, title: "Favorites")
        let destination = EmptyFeatureState<EntryHostState>.entryPoint(input: input)
        let store = TestStore(initial: EntryHostState())
        var wrappers: [MiddlewareWrapper<EntryHostState>] = []

        await store.subscribe { store in
            wrappers = EmptyFeatureState<EntryHostState>.registerMiddlewares(in: store)
            return wrappers
        }

        #expect(destination.input == input)
        #expect(wrappers.isEmpty)
    }

    @TestStoreActor
    @Test("TestStore explicitly subscribes feature and legacy middleware with test environments")
    func storeExplicitlySubscribesFeatureMiddleware() async {
        let store = TestStore(initial: AutoRegistrationHostState())
        await store.subscribe { _ -> [MiddlewareWrapper<AutoRegistrationHostState>] in
            AutoRegisteredFeatureMiddleware<AutoRegistrationHostState>.self
            AutoRegisteredLegacyMiddleware<AutoRegistrationHostState>.self
        }

        await store.dispatch(Actions.CaptureMiddlewareEnvironment())
        store.wait()

        #expect(store.state.result.marker == "test")
        #expect(store.state.result.legacyHandled == true)
    }

    @Test("Reducers nested at multiple levels inside FeatureState receive actions")
    func nestedReducersReceiveActions() async {
        let store = await TestStore(initial: NestedHostState())

        await store.dispatch(Actions.IncrementEveryLevel())

        let state = await store.state
        #expect(state.root.value == 1)
        #expect(state.feature.form.value == 1)
        #expect(state.feature.form.child.value == 1)
        #expect(state.feature.flow == .handled)
    }

    @Test("InitialSetup reaches reducers nested inside FeatureState")
    func nestedInitialSetupReceivesRootState() async {
        let store = await TestStore(initial: SetupHostState(seed: SeedForm(value: 21)))

        let state = await store.state
        #expect(state.feature.form.configuredValue == 42)
        #expect(state.feature.form.child.configuredValue == 63)
    }

    @Test("TestStore accepts a feature-only middleware with an explicit environment")
    func storeExplicitFeatureEnvironment() async {
        let store = await TestStore(initial: AutoRegistrationHostState())
        await store.subscribe(
            AutoRegisteredFeatureMiddleware<AutoRegistrationHostState>.self,
            environment: AutoRegisteredFeatureEnvironment(marker: "injected")
        )

        await store.dispatch(Actions.CaptureMiddlewareEnvironment())
        await store.wait()

        #expect(await store.state.result.marker == "injected")
    }

    @Test("Form field updates automatically mutate nested forms inside FeatureState")
    func formFieldUpdatesMutateNestedFormInsideFeatureState() async {
        let store = await TestStore(initial: NestedHostState())

        await store.dispatch(
            Actions.UpdateFormField(
                keyPath: \NestedFeatureForm.value,
                value: 99
            )
        )

        let state = await store.state
        #expect(state.feature.form.value == 99)
        #expect(state.feature.form.child.value == 0)
        #expect(state.root.value == 0)
    }

    @Test("Multiple feature states mutate independently without cross-feature interference")
    func multipleFeatureStatesMutateIndependently() async {
        let store = await TestStore(initial: CounterFeaturesHostState())

        await store.dispatch(Actions.IncrementFirstCounter())

        var state = await store.state
        #expect(state.firstCounter.value == 1)
        #expect(state.secondCounter.value == 0)

        await store.dispatch(Actions.IncrementSecondCounter())

        state = await store.state
        #expect(state.firstCounter.value == 1)
        #expect(state.secondCounter.value == 1)
    }
}

// MARK: - Actions

private extension Actions {
    struct CaptureMiddlewareEnvironment: Action {}
    struct IncrementEveryLevel: Action {}
    struct IncrementFirstCounter: Action {}
    struct IncrementSecondCounter: Action {}
}

// MARK: - Public API fixtures

private struct EntryInput: Equatable, Sendable {
    let id: Int
    let title: String
}

private struct EntryDestination: View {
    let input: EntryInput

    var body: some View {
        EmptyView()
    }
}

private struct EmptyFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {
    }

    static func entryPoint(input: EntryInput) -> EntryDestination {
        EntryDestination(input: input)
    }
}

private struct EntryHostState: AppReducer {
    var feature = EmptyFeatureState<EntryHostState>()
}

private protocol AutoRegisteredFeatureHost: AppReducer {
    associatedtype Environments: AutoRegisteredFeatureEnvironmentProviding

    var feature: AutoRegisteredFeatureState<Self> { get }
}

private protocol AutoRegisteredFeatureEnvironmentProviding {
    static var feature: AutoRegisteredFeatureEnvironment { get }
}

private struct AutoRegisteredFeatureEnvironment: Sendable {
    let marker: String
}

private enum AutoRegisteredEnvironments: AutoRegisteredFeatureEnvironmentProviding {
    static let feature = AutoRegisteredFeatureEnvironment(marker: "registered")
}

private struct AutoRegisteredFeatureState<Host: AutoRegisteredFeatureHost>: FeatureState {
    typealias FeatureRouting = EmptyRouting

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(
        in store: any Store<Host>
    ) -> [MiddlewareWrapper<Host>] {
        AutoRegisteredFeatureMiddleware<Host>.self
        AutoRegisteredLegacyMiddleware<Host>.self
    }
}

private struct AutoRegistrationHostState: AppReducer, AutoRegisteredFeatureHost {
    typealias Environments = AutoRegisteredEnvironments

    var feature = AutoRegisteredFeatureState<AutoRegistrationHostState>()
    var result = MiddlewareResultForm()
}

private struct MiddlewareResultForm: UDF.Form {
    var marker: String?
    var legacyHandled = false
}

private final class AutoRegisteredFeatureMiddleware<State: AutoRegisteredFeatureHost>: Middleware<State>, @unchecked Sendable {
    typealias Environment = AutoRegisteredFeatureEnvironment

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment {
        State.Environments.feature
    }

    static func buildTestEnvironment(for store: some Store<State>) -> Environment {
        AutoRegisteredFeatureEnvironment(marker: "test")
    }

    func reduce(_ action: some Action, for state: State) {
        guard action is Actions.CaptureMiddlewareEnvironment else {
            return
        }

        store.dispatch(
            Actions.UpdateFormField(
                keyPath: \MiddlewareResultForm.marker,
                value: environment.marker
            )
        )
    }
}

private final class AutoRegisteredLegacyMiddleware<State: AutoRegisteredFeatureHost>: Middleware<State>, @unchecked Sendable {
    var environment: Void!

    func reduce(_ action: some Action, for state: State) {
        guard action is Actions.CaptureMiddlewareEnvironment else {
            return
        }

        store.dispatch(
            Actions.UpdateFormField(
                keyPath: \MiddlewareResultForm.legacyHandled,
                value: true
            )
        )
    }
}

// MARK: - Nested reducer fixtures

private struct NestedHostState: AppReducer {
    var root = RootCounter()
    var feature = NestedFeatureState<NestedHostState>()
}

private struct RootCounter: UDF.Form {
    var value = 0

    mutating func reduce(_ action: some Action) {
        guard action is Actions.IncrementEveryLevel else {
            return
        }
        value += 1
    }
}

private struct NestedFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    var form = NestedFeatureForm()
    var flow = NestedFeatureFlow()

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct NestedFeatureForm: UDF.Form {
    var value = 0
    var child = DeepCounter()

    mutating func reduce(_ action: some Action) {
        guard action is Actions.IncrementEveryLevel else {
            return
        }
        value += 1
    }
}

private struct DeepCounter: UDF.Form {
    var value = 0

    mutating func reduce(_ action: some Action) {
        guard action is Actions.IncrementEveryLevel else {
            return
        }
        value += 1
    }
}

private enum NestedFeatureFlow: Flow {
    case idle
    case handled

    init() {
        self = .idle
    }

    mutating func reduce(_ action: some Action) {
        guard action is Actions.IncrementEveryLevel else {
            return
        }
        self = .handled
    }
}

// MARK: - Initial setup fixtures

private protocol SetupFeatureHost: AppReducer {
    var seed: SeedForm { get }
    var feature: SetupFeatureState<Self> { get }
}

private struct SetupHostState: AppReducer, SetupFeatureHost {
    var seed = SeedForm()
    var feature = SetupFeatureState<SetupHostState>()
}

private struct SeedForm: UDF.Form {
    var value = 0
}

private struct SetupFeatureState<Host: SetupFeatureHost>: FeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    var form = SetupFeatureForm<Host>()

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct SetupFeatureForm<Host: SetupFeatureHost>: UDF.Form, InitialSetup {
    var configuredValue = 0
    var child = SetupLeafForm<Host>()

    mutating func initialSetup(with state: Host) {
        configuredValue = state.seed.value * 2
    }
}

private struct SetupLeafForm<Host: SetupFeatureHost>: UDF.Form, InitialSetup {
    var configuredValue = 0

    mutating func initialSetup(with state: Host) {
        configuredValue = state.seed.value * 3
    }
}

// MARK: - Dual feature fixtures

private struct CounterFeaturesHostState: AppReducer {
    var firstCounter = FirstCounterFeatureState<CounterFeaturesHostState>()
    var secondCounter = SecondCounterFeatureState<CounterFeaturesHostState>()
}

private struct FirstCounterFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    var value = 0

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    mutating func reduce(_ action: some Action) {
        if action is Actions.IncrementFirstCounter {
            value += 1
        }
    }

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct SecondCounterFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    var value = 0

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    mutating func reduce(_ action: some Action) {
        if action is Actions.IncrementSecondCounter {
            value += 1
        }
    }

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}
