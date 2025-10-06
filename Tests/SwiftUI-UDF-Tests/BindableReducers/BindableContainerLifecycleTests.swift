//
//  BindableContainerLifecycleTests.swift
//
//
//  Created by Max Kuznetsov on 07.09.2024.
//

import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite struct BindableContainerLifecycleTests {
    struct Item: Identifiable {
        struct ID: Hashable {
            var value: Int
        }

        var id: ID
    }

    struct ItemsForm: UDF.Form {}

    struct AppState: AppReducer {
        @BindableReducer(ItemsForm.self, bindedTo: ItemsContainer.self)
        fileprivate var itemsForm
    }

    @Test func bindableContainerLifecycle() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])

        let itemId = Item.ID(value: 1)
        let itemsContainer = ItemsContainer(id: itemId)
        var window: PlatformWindow? = await PlatformWindow.render(view: itemsContainer)

        await window?.redraw()

        var success = await waitForCondition { store.state.itemsForm[itemId] != nil }
        #expect(success)

        window = nil
        await window?.redraw()

        success = await waitForCondition { store.state.itemsForm[itemId] == nil }
        #expect(success)
    }
}

// MARK: Container
private extension BindableContainerLifecycleTests {
    struct ItemsContainer: BindableContainer {
        typealias ContainerComponent = ItemsComponent

        var id: Item.ID

        func scope(for state: AppState) -> Scope {
            state.itemsForm[id]
        }

        func map(store: EnvironmentStore<AppState>) -> ItemsComponent.Props {
            .init()
        }
    }

    struct ItemsComponent: Component {
        struct Props {}

        var props: Props

        var body: some View {
            Text("body")
        }
    }
}
