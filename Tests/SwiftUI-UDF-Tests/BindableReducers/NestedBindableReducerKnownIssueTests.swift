import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

/// A `@BindableReducer` declared inside the reducer of another `@BindableReducer` is never created: the runtime does
/// not walk the dictionary storage of a bindable reducer, so the inner container's load and binded actions never
/// reach it. Declare the inner `@BindableReducer` next to the outer one instead.
///
/// See https://github.com/Maks-Jago/SwiftUI-UDF/issues/56.
@TestStoreActor
@Suite struct NestedBindableReducerKnownIssueTests {
    struct Bump: Action {}

    struct InnerForm: UDF.Form {
        var bumps = 0

        mutating func reduce(_ action: some Action) {
            if action is Bump { bumps += 1 }
        }
    }

    struct OuterForm: UDF.Form {
        var bumps = 0

        @BindableReducer(InnerForm.self, bindedTo: InnerContainer.self)
        var inner

        mutating func reduce(_ action: some Action) {
            if action is Bump { bumps += 1 }
        }
    }

    struct NestedState: AppReducer {
        @BindableReducer(OuterForm.self, bindedTo: OuterContainer.self)
        var outer
    }

    // MARK: Known issue

    @Test func whenInnerContainerLoads_TheInnerBindableReducerShouldBeCreated() async throws {
        let store = TestStore(initial: NestedState())

        await store.dispatch(Actions._OnContainerDidLoad(containerType: OuterContainer.self, id: 1))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: InnerContainer.self, id: 1))
        store.wait()

        let outer: OuterForm = try #require(store.state.outer[1])

        withKnownIssue("A @BindableReducer inside another @BindableReducer is never created (issue #56)") {
            let inner: InnerForm? = outer.inner[1]
            #expect(inner != nil, "Loading InnerContainer should create the inner bindable reducer")
        }
    }

    @Test func whenInnerContainerLoadsWithAnotherID_TheInnerBindableReducerShouldBeCreated() async throws {
        let store = TestStore(initial: NestedState())

        await store.dispatch(Actions._OnContainerDidLoad(containerType: InnerContainer.self, id: 2))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: OuterContainer.self, id: 1))
        store.wait()

        let outer: OuterForm = try #require(store.state.outer[1])

        withKnownIssue("A @BindableReducer inside another @BindableReducer is never created (issue #56)") {
            let inner: InnerForm? = outer.inner[2]
            #expect(inner != nil, "Loading InnerContainer should create the inner bindable reducer regardless of the order and the IDs")
        }
    }

    @Test func whenBindedActionDispatchedToInnerContainer_TheInnerBindableReducerShouldReduceIt() async throws {
        let store = TestStore(initial: NestedState())

        await store.dispatch(Actions._OnContainerDidLoad(containerType: OuterContainer.self, id: 1))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: InnerContainer.self, id: 1))
        await store.dispatch(Bump().binded(to: InnerContainer.self, by: 1))
        store.wait()

        let outer: OuterForm = try #require(store.state.outer[1])
        #expect(outer.bumps == 0, "An action binded to the inner container must not reach the outer reducer")

        withKnownIssue("A @BindableReducer inside another @BindableReducer is never created (issue #56)") {
            let inner: InnerForm? = outer.inner[1]
            #expect(inner?.bumps == 1, "The binded action should reach the inner bindable reducer")
        }
    }

    // MARK: What works today

    struct PlainFlow: UDF.Flow {
        var bumps = 0

        mutating func reduce(_ action: some Action) {
            if action is Bump { bumps += 1 }
        }
    }

    struct PlainForm: UDF.Form {
        var bumps = 0
        var flow = PlainFlow()
        var form = InnerForm()

        mutating func reduce(_ action: some Action) {
            if action is Bump { bumps += 1 }
        }
    }

    struct PlainNestedState: AppReducer {
        @BindableReducer(PlainForm.self, bindedTo: PlainContainer.self)
        var plain
    }

    @Test func whenBindedActionDispatched_PlainFormAndFlowNestedInTheBoundFormShouldReduceItOnce() async throws {
        let store = TestStore(initial: PlainNestedState())

        await store.dispatch(Actions._OnContainerDidLoad(containerType: PlainContainer.self, id: 1))
        await store.dispatch(Bump().binded(to: PlainContainer.self, by: 1))
        store.wait()

        let plain = try #require(store.state.plain[1])
        #expect(plain.bumps == 1)

        #expect(plain.flow.bumps == 1)
        #expect(plain.form.bumps == 1)
    }

    struct SiblingState: AppReducer {
        @BindableReducer(InnerForm.self, bindedTo: InnerContainer.self)
        var inner

        @BindableReducer(OuterFormWithoutInner.self, bindedTo: OuterContainer.self)
        var outer
    }

    struct OuterFormWithoutInner: UDF.Form {
        var bumps = 0

        mutating func reduce(_ action: some Action) {
            if action is Bump { bumps += 1 }
        }
    }

    @Test func whenBindableReducersAreDeclaredSideBySide_EachOneShouldReduceItsOwnBindedActions() async throws {
        let store = TestStore(initial: SiblingState())

        await store.dispatch(Actions._OnContainerDidLoad(containerType: OuterContainer.self, id: 1))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: InnerContainer.self, id: 1))
        await store.dispatch(Bump().binded(to: InnerContainer.self, by: 1))
        store.wait()

        let inner = try #require(store.state.inner[1])
        #expect(inner.bumps == 1)

        let outer = try #require(store.state.outer[1])
        #expect(outer.bumps == 0)
    }
}

// MARK: Containers
private extension NestedBindableReducerKnownIssueTests {
    struct OuterContainer: BindableContainer {
        typealias ContainerComponent = FixtureComponent

        var id: Int

        func scope(for state: NestedState) -> Scope {
            state.outer[id]
        }

        func map(store: EnvironmentStore<NestedState>) -> FixtureComponent.Props {
            .init()
        }
    }

    struct InnerContainer: BindableContainer {
        typealias ContainerComponent = FixtureComponent

        var id: Int

        func scope(for state: NestedState) -> Scope {
            state.outer[id]
        }

        func map(store: EnvironmentStore<NestedState>) -> FixtureComponent.Props {
            .init()
        }
    }

    struct PlainContainer: BindableContainer {
        typealias ContainerComponent = FixtureComponent

        var id: Int

        func scope(for state: PlainNestedState) -> Scope {
            state.plain[id]
        }

        func map(store: EnvironmentStore<PlainNestedState>) -> FixtureComponent.Props {
            .init()
        }
    }

    struct FixtureComponent: Component {
        struct Props {}

        var props: Props

        var body: some View {
            Text("body")
        }
    }
}
