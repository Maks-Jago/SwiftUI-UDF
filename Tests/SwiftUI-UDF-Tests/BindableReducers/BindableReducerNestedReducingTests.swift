import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

/// A binded action must be reduced the same way as an unbound one: once by the bound reducer and once by every
/// reducer nested in it.
@TestStoreActor
@Suite struct BindableReducerNestedReducingTests {
    struct Increment: Action {}

    struct Leaf: UDF.Form {
        var count = 0
        var title = ""

        mutating func reduce(_ action: some Action) {
            if action is Increment { count += 1 }
        }
    }

    struct Branch: Reducible {
        var count = 0
        var leaf = Leaf()

        mutating func reduce(_ action: some Action) {
            if action is Increment { count += 1 }
        }
    }

    struct Counter: Reducible, Codable {
        var count = 0

        mutating func reduce(_ action: some Action) {
            if action is Increment { count += 1 }
        }
    }

    struct MemorySource: CacheSource {
        init(key: String) {}
        func save<T: Encodable>(_ value: T) {}
        func load<T: Decodable>() -> T? { nil }
        func remove() {}
    }

    struct Outer: UDF.Form {
        var count = 0
        var leaf = Leaf()
        var branch = Branch()

        @Cached(key: "bindable_nested_reducing_counter", defaultValue: Counter(), storage: MemorySource(key: "bindable_nested_reducing_counter"))
        var counter

        mutating func reduce(_ action: some Action) {
            if action is Increment { count += 1 }
        }
    }

    fileprivate struct BoundState: AppReducer {
        @BindableReducer(Outer.self, bindedTo: OuterContainer.self)
        var outer
    }

    fileprivate struct UnboundState: AppReducer {
        var outer = Outer()
    }

    @Test func whenBindedActionDispatched_AWrappedReducerNestedInTheBoundReducerShouldReduceItOnce() async throws {
        let store = TestStore(initial: BoundState())
        await store.dispatch(Actions._OnContainerDidLoad(containerType: OuterContainer.self, id: 1))

        await store.dispatch(Increment().binded(to: OuterContainer.self, by: 1))

        let outer = try #require(store.state.outer[1])
        #expect(outer.count == 1)

        // `RuntimeReducing.bindableReduce` walks the bound reducer's properties twice, so a `@Cached` reducer
        // nested in it reduces a binded action twice. Remove the wrapper once that is fixed.
        withKnownIssue("Reducers nested in a bindable reducer reduce each binded action twice") {
            #expect(outer.counter.count == 1)
        }
    }

    @Test func whenSameActionsDispatchedBindedAndUnbinded_ReducedStateShouldBeTheSame() async throws {
        let bound = TestStore(initial: BoundState())
        let unbound = TestStore(initial: UnboundState())
        await bound.dispatch(Actions._OnContainerDidLoad(containerType: OuterContainer.self, id: 1))

        func dispatchToBoth(_ action: some Action) async {
            await bound.dispatch(action.binded(to: OuterContainer.self, by: 1))
            await unbound.dispatch(action)
        }

        await dispatchToBoth(Increment())
        await dispatchToBoth(Actions.UpdateFormField(keyPath: \Leaf.title, value: "first"))
        await dispatchToBoth(Increment())
        await dispatchToBoth(Actions.UpdateFormField(keyPath: \Leaf.title, value: "second"))
        await dispatchToBoth(Increment())

        let boundOuter = try #require(bound.state.outer[1])
        #expect(unbound.state.outer.leaf.count == 3)

        // Nested reducers reduce a binded action twice, so the bound state drifts from the unbound one.
        // Remove the wrapper once that is fixed.
        withKnownIssue("Reducers nested in a bindable reducer reduce each binded action twice") {
            #expect(boundOuter == unbound.state.outer, "Binding an action must not change how it is reduced")
        }
    }
}

// MARK: Container
private extension BindableReducerNestedReducingTests {
    struct OuterContainer: BindableContainer {
        typealias ContainerComponent = OuterComponent

        var id: Int

        func scope(for state: BoundState) -> Scope {
            state.outer[id]
        }

        func map(store: EnvironmentStore<BoundState>) -> OuterComponent.Props {
            .init()
        }
    }

    struct OuterComponent: Component {
        struct Props {}

        var props: Props

        var body: some View {
            Text("body")
        }
    }
}
