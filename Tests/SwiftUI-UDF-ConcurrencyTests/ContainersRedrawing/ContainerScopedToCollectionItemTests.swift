import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@Suite struct ContainerScopedToCollectionItemTests {
    @propertyWrapper
    final class Box<Value> {
        private var box: Value

        init(wrappedValue: Value) {
            box = wrappedValue
        }

        var wrappedValue: Value {
            get { box }
            set { box = newValue }
        }
    }

    private struct TestStoreLogger: ActionLogger {
        var actionFilters: [ActionFilter] = [VerboseActionFilter()]
        var actionDescriptor: ActionDescriptor = StringDescribingActionDescriptor()

        func log(_ action: LoggingAction, description: String) {
            print("Reduce\t\t", description)
        }
    }

    // MARK: - State

    struct AppState: AppReducer {
        var items = ItemsStore()
        var sideForm = SideForm()
    }

    struct Item: Identifiable, Equatable, Scope {
        struct ID: Hashable { var value: Int }

        var id: ID
        var title: String

        static var empty: Item { .init(id: .init(value: -1), title: "") }
    }

    // A second field alongside the collection, mirroring how real containers combine
    // `state.allBooks.bookBy(id:)` with `state.bookForm`, `state.userForm`, etc.
    struct SideForm: UDF.Form {
        var flag: Bool = false
    }

    struct ItemsStore: Reducible {
        var byId: [Item.ID: Item] = [:]

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItem<Item>:
                byId[action.item.id] = action.item
            case let action as TestActions.UpdateItemTitle:
                byId[action.id]?.title = action.title
            case let action as TestActions.RemoveItem:
                byId.removeValue(forKey: action.id)
            default:
                break
            }
        }

        // Mirrors `AllBooks.bookBy(id:)` from the app: non-optional, falls back to `.empty`.
        func itemBy(id: Item.ID) -> Item {
            byId[id] ?? .empty
        }
    }

    enum TestActions {
        struct UpdateItemTitle: Action {
            let id: Item.ID
            let title: String
        }

        struct RemoveItem: Action {
            let id: Item.ID
        }
    }

    // MARK: - Tests

    @Test
    @MainActor func unrelatedItemChangeDoesNotRedraw() async {
        let initialState = AppState(
            items: ItemsStore(byId: [
                .init(value: 1): .init(id: .init(value: 1), title: "target"),
                .init(value: 2): .init(id: .init(value: 2), title: "other")
            ])
        )
        let store = EnvironmentStore(initial: initialState, logger: TestStoreLogger())

        let container = ItemContainer(itemId: .init(value: 1))
        let window = await PlatformWindow.render(view: container.with(store: store))

        var success = await waitForMainActorCondition { container.renderingCount == 1 }
        #expect(success)

        // Mutate a *different* item in the same collection.
        store.dispatch(TestActions.UpdateItemTitle(id: .init(value: 2), title: "other changed"))
        await waitForMainActorCondition { store.state.items.byId[.init(value: 2)]?.title == "other changed" }

        window.redraw()
        // Give the run loop a beat, then assert the count did NOT advance.
        success = await waitForMainActorCondition { container.renderingCount == 1 }
        #expect(success)
        #expect(container.renderingCount == 1)
    }

    @Test
    @MainActor func targetItemChangeRedraws() async {
        // Two items present -> proves diffing reacts to the *specific* item,
        // not just to "the store has any content".
        let initialState = AppState(
            items: ItemsStore(byId: [
                .init(value: 1): .init(id: .init(value: 1), title: "target"),
                .init(value: 2): .init(id: .init(value: 2), title: "other")
            ])
        )
        let store = EnvironmentStore(initial: initialState, logger: TestStoreLogger())

        let container = ItemContainer(itemId: .init(value: 1))
        let window = await PlatformWindow.render(view: container.with(store: store))

        var success = await waitForMainActorCondition { container.renderingCount == 1 }
        #expect(success)

        store.dispatch(TestActions.UpdateItemTitle(id: .init(value: 1), title: "target changed"))
        await waitForMainActorCondition { store.state.items.byId[.init(value: 1)]?.title == "target changed" }

        window.redraw()
        success = await waitForMainActorCondition { container.renderingCount == 2 }
        #expect(success)
    }

    @Test
    @MainActor func targetItemLoadingFromEmptyRedraws() async {
        // Item not present yet -> itemBy(id:) resolves to .empty.
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let container = ItemContainer(itemId: .init(value: 1))
        let window = await PlatformWindow.render(view: container.with(store: store))

        var success = await waitForMainActorCondition { container.renderingCount == 1 }
        #expect(success)
        #expect(container.renderingCount == 1) // rendered once with `.empty`

        store.dispatch(Actions.DidLoadItem(item: Item(id: .init(value: 1), title: "loaded")))
        await waitForMainActorCondition { store.state.items.byId[.init(value: 1)] != nil }

        window.redraw()
        success = await waitForMainActorCondition { container.renderingCount == 2 }
        #expect(success)
    }

    @Test
    @MainActor func targetItemRemovalRedraws() async {
        // Two items present -> proves removal-driven redraw isn't just an
        // artifact of the store becoming empty overall.
        let initialState = AppState(
            items: ItemsStore(byId: [
                .init(value: 1): .init(id: .init(value: 1), title: "target"),
                .init(value: 2): .init(id: .init(value: 2), title: "other")
            ])
        )
        let store = EnvironmentStore(initial: initialState, logger: TestStoreLogger())

        let container = ItemContainer(itemId: .init(value: 1))
        let window = await PlatformWindow.render(view: container.with(store: store))

        var success = await waitForMainActorCondition { container.renderingCount == 1 }
        #expect(success)

        store.dispatch(TestActions.RemoveItem(id: .init(value: 1)))
        await waitForMainActorCondition { store.state.items.byId[.init(value: 1)] == nil }

        window.redraw()
        // itemBy(id:) now resolves to .empty -> Scope must change -> redraw fires again.
        success = await waitForMainActorCondition { container.renderingCount == 2 }
        #expect(success)
        // The unrelated item must still be present -> confirms the redraw was
        // driven by the target's removal, not by the store becoming empty.
        #expect(store.state.items.byId[.init(value: 2)] != nil)
    }

    // Mirrors the real containers' shape: `Scope` combines the collection-scoped item
    // together with another, unrelated piece of state (like `bookForm`/`userForm`).
    @Test
    @MainActor func combinedScopePartsRedrawIndependently() async {
        let initialState = AppState(
            items: ItemsStore(byId: [
                .init(value: 1): .init(id: .init(value: 1), title: "target"),
                .init(value: 2): .init(id: .init(value: 2), title: "other")
            ])
        )
        let store = EnvironmentStore(initial: initialState, logger: TestStoreLogger())

        let container = CombinedScopeItemContainer(itemId: .init(value: 1))
        let window = await PlatformWindow.render(view: container.with(store: store))

        var success = await waitForMainActorCondition { container.renderingCount == 1 }
        #expect(success)

        // Part 1 of the combined scope changes -> must redraw.
        store.dispatch(TestActions.UpdateItemTitle(id: .init(value: 1), title: "target changed"))
        await waitForMainActorCondition { store.state.items.byId[.init(value: 1)]?.title == "target changed" }
        window.redraw()
        success = await waitForMainActorCondition { container.renderingCount == 2 }
        #expect(success)

        // Part 2 of the combined scope changes -> must also redraw.
        store.dispatch(Actions.UpdateFormField(keyPath: \SideForm.flag, value: true))
        await waitForMainActorCondition { store.state.sideForm.flag == true }
        window.redraw()
        success = await waitForMainActorCondition { container.renderingCount == 3 }
        #expect(success)

        // A different, unrelated item changes -> neither part of the combined scope
        // is affected -> must NOT redraw.
        store.dispatch(TestActions.UpdateItemTitle(id: .init(value: 2), title: "other changed"))
        await waitForMainActorCondition { store.state.items.byId[.init(value: 2)]?.title == "other changed" }
        window.redraw()
        success = await waitForMainActorCondition { container.renderingCount == 3 }
        #expect(success)
        #expect(container.renderingCount == 3)
    }
}

// MARK: - ItemContainer

extension ContainerScopedToCollectionItemTests {
    struct ItemContainer: Container {
        typealias ContainerComponent = ItemComponent

        let itemId: Item.ID

        @Box var renderingCount: Int = 0

        func scope(for state: AppState) -> Scope {
            state.items.itemBy(id: itemId)
        }

        func map(store: EnvironmentStore<AppState>) -> ContainerComponent.Props {
            renderingCount += 1
            print("ItemContainer: renderingCount - \(renderingCount)")

            return .init(title: store.state.items.itemBy(id: itemId).title)
        }
    }

    struct ItemComponent: Component {
        struct Props {
            var title: String
        }

        var props: Props

        var body: some View {
            Text(props.title)
        }
    }

    // MARK: - CombinedScopeItemContainer

    struct CombinedScopeItemContainer: Container {
        typealias ContainerComponent = ItemComponent

        let itemId: Item.ID

        @Box var renderingCount: Int = 0

        func scope(for state: AppState) -> Scope {
            state.items.itemBy(id: itemId)
            state.sideForm
        }

        func map(store: EnvironmentStore<AppState>) -> ContainerComponent.Props {
            renderingCount += 1
            print("CombinedScopeItemContainer: renderingCount - \(renderingCount)")

            return .init(title: store.state.items.itemBy(id: itemId).title)
        }
    }
}
