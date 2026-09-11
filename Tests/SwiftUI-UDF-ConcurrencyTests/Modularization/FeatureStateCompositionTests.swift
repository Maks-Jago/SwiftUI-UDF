import SwiftUI
import Testing
@testable import UDF
import UDFSwiftTesting

@Suite struct FeatureStateCompositionTests {
    @TestStoreActor
    @Test("FeatureState forwards its entry payload and defaults to no middleware")
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
    @Test("A public registration witness inherits MiddlewareBuilder")
    func registrationWitnessUsesInheritedBuilder() async {
        let store = TestStore(initial: PublicHostState())
        var wrappers: [MiddlewareWrapper<PublicHostState>] = []

        await store.subscribe { store in
            wrappers = PublicFeatureState<PublicHostState>.registerMiddlewares(in: store)
            return wrappers
        }

        #expect(wrappers.count == 2)

        await store.dispatch(RecordEnvironment())
        store.wait()

        #expect(store.state.result.marker == "registered")
        #expect(store.state.result.legacyHandled == true)
    }

    @Test("Reducers nested at multiple levels inside FeatureState receive actions")
    func nestedReducersReceiveActions() async {
        let store = await TestStore(initial: NestedHostState())

        await store.dispatch(IncrementEveryLevel())

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
    func testStoreExplicitFeatureEnvironment() async {
        let store = await TestStore(initial: PublicHostState())
        await store.subscribe(
            PublicFeatureMiddleware<PublicHostState>.self,
            environment: PublicFeatureEnvironment(marker: "injected")
        )

        await store.dispatch(RecordEnvironment())
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
        let store = await TestStore(initial: DualFeatureHostState())

        await store.dispatch(IncrementFeatureOne())

        var state = await store.state
        #expect(state.feature1.value == 1)
        #expect(state.feature2.value == 0)

        await store.dispatch(IncrementFeatureTwo())

        state = await store.state
        #expect(state.feature1.value == 1)
        #expect(state.feature2.value == 1)
    }
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

    static func entryPoint(input: EntryInput) -> EntryDestination {
        EntryDestination(input: input)
    }
}

private struct EntryHostState: AppReducer {
    var feature = EmptyFeatureState<EntryHostState>()
}

private protocol PublicFeatureHost: AppReducer {
    associatedtype Environments: PublicFeatureEnvironmentProviding

    var feature: PublicFeatureState<Self> { get }
}

private protocol PublicFeatureEnvironmentProviding {
    static var feature: PublicFeatureEnvironment { get }
}

private struct PublicFeatureEnvironment: Sendable {
    let marker: String
}

private enum PublicEnvironments: PublicFeatureEnvironmentProviding {
    static let feature = PublicFeatureEnvironment(marker: "registered")
}

private struct PublicFeatureState<Host: PublicFeatureHost>: FeatureState {
    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(
        in store: any Store<Host>
    ) -> [MiddlewareWrapper<Host>] {
        PublicFeatureMiddleware<Host>(
            store: store,
            environment: Host.Environments.feature
        )
        PublicLegacyMiddleware<Host>.self
    }
}

private struct PublicHostState: AppReducer, PublicFeatureHost {
    typealias Environments = PublicEnvironments

    var feature = PublicFeatureState<PublicHostState>()
    var result = PublicResultForm()
}

private struct PublicResultForm: UDF.Form {
    var marker: String?
    var legacyHandled = false
}

private struct RecordEnvironment: Action {}

private final class PublicFeatureMiddleware<State: PublicFeatureHost>: FeatureMiddleware<State>, @unchecked Sendable {
    typealias Environment = PublicFeatureEnvironment

    var environment: Environment!

    func reduce(_ action: some Action, for state: State) {
        guard action is RecordEnvironment else {
            return
        }

        store.dispatch(
            Actions.UpdateFormField(
                keyPath: \PublicResultForm.marker,
                value: environment.marker
            )
        )
    }
}

private final class PublicLegacyMiddleware<State: PublicFeatureHost>: Middleware<State>, @unchecked Sendable {
    var environment: Void!

    func reduce(_ action: some Action, for state: State) {
        guard action is RecordEnvironment else {
            return
        }

        store.dispatch(
            Actions.UpdateFormField(
                keyPath: \PublicResultForm.legacyHandled,
                value: true
            )
        )
    }
}

// MARK: - Nested reducer fixtures

private struct IncrementEveryLevel: Action {}

private struct NestedHostState: AppReducer {
    var root = RootCounter()
    var feature = NestedFeatureState<NestedHostState>()
}

private struct RootCounter: UDF.Form {
    var value = 0

    mutating func reduce(_ action: some Action) {
        guard action is IncrementEveryLevel else {
            return
        }
        value += 1
    }
}

private struct NestedFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host

    var form = NestedFeatureForm()
    var flow = NestedFeatureFlow()

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct NestedFeatureForm: UDF.Form {
    var value = 0
    var child = DeepCounter()

    mutating func reduce(_ action: some Action) {
        guard action is IncrementEveryLevel else {
            return
        }
        value += 1
    }
}

private struct DeepCounter: UDF.Form {
    var value = 0

    mutating func reduce(_ action: some Action) {
        guard action is IncrementEveryLevel else {
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
        guard action is IncrementEveryLevel else {
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

    var form = SetupFeatureForm<Host>()

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

private struct IncrementFeatureOne: Action {}
private struct IncrementFeatureTwo: Action {}

private struct DualFeatureHostState: AppReducer {
    var feature1 = FeatureOneState<DualFeatureHostState>()
    var feature2 = FeatureTwoState<DualFeatureHostState>()
}

private struct FeatureOneState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    var value = 0

    mutating func reduce(_ action: some Action) {
        if action is IncrementFeatureOne {
            value += 1
        }
    }

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct FeatureTwoState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    var value = 0

    mutating func reduce(_ action: some Action) {
        if action is IncrementFeatureTwo {
            value += 1
        }
    }

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}
