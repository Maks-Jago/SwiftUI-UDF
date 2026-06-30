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

@Suite(.serialized)
struct BindableContainerLifecycleTests {
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

    @MainActor
    @Test("onBindableReducerDidLoad and onBindableReducerDidUnload are called for a single container")
    func singleContainerLifecycle() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        let itemId = Item.ID(value: 1)
        
        var didLoadCalled = false
        var didUnloadCalled = false

        await confirmation("didLoad", expectedCount: 1) { confirmLoad in
            await confirmation("didUnload", expectedCount: 1) { confirmUnload in
                let container = ItemsContainer(
                    id: itemId,
                    onBindableReducerDidLoad: {
                        didLoadCalled = true
                        confirmLoad()
                    },
                    onBindableReducerDidUnload: {
                        didUnloadCalled = true
                        confirmUnload()
                    }
                )
                var window: PlatformWindow? = await PlatformWindow.render(view: container)
                window?.redraw()

                // Wait for the state to load and callback to fire
                let success = await waitForMainActorCondition { store.state.itemsForm[itemId] != nil && didLoadCalled }
                #expect(success)

                // Unload the container using release
                window?.release()
                window = nil
                window?.redraw()

                // Wait for the state to unload completely and callback to fire
                let unloaded = await waitForMainActorCondition { store.state.itemsForm[itemId] == nil && didUnloadCalled }
                #expect(unloaded)
            }
        }
    }

    @MainActor
    @Test("onBindableReducerDidLoad fires once on first load, and onBindableReducerDidUnload fires once when last container unloads")
    func multipleContainersWithSameID() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        let itemId = Item.ID(value: 1)
        
        let manager = TestStateViewModel()
        let root = TestStateView(manager: manager)
        var window: PlatformWindow? = await PlatformWindow.render(view: root)
        
        var didLoadCalled = false
        var didUnloadCalled = false

        await confirmation("didLoad", expectedCount: 1) { confirmLoad in
            await confirmation("didUnload", expectedCount: 1) { confirmUnload in
                // 1. Load the first container
                let container1 = ItemsContainer(
                    id: itemId,
                    onBindableReducerDidLoad: {
                        didLoadCalled = true
                        confirmLoad()
                    },
                    onBindableReducerDidUnload: {
                        didUnloadCalled = true
                        confirmUnload()
                    }
                )
                manager.containers = [.init(container: container1, isVisible: true)]
                window?.redraw()

                // Wait for the state to load and callback to fire
                var success = await waitForMainActorCondition { store.state.itemsForm[itemId] != nil && didLoadCalled }
                #expect(success)

                // 2. Load the second container with the same ID
                let container2 = ItemsContainer(
                    id: itemId,
                    onBindableReducerDidLoad: {
                        // We do not set didLoadCalled here because expectedCount is 1, so it shouldn't fire again
                        confirmLoad()
                    },
                    onBindableReducerDidUnload: {
                        didUnloadCalled = true
                        confirmUnload()
                    }
                )
                manager.containers.append(.init(container: container2, isVisible: true))
                window?.redraw()
                
                // Wait for the store to process the load action
                await sleep(for: 0.1)

                // 3. Unload the first container
                manager.containers[0].isVisible = false
                window?.redraw()

                // Wait a bit to make sure didUnload doesn't fire yet (since container2 is still active)
                try? await Task.sleep(for: .milliseconds(200))

                // 4. Unload the second container (the last instance)
                manager.containers[1].isVisible = false
                window?.redraw()

                // Wait for the state to unload completely and callback to fire
                success = await waitForMainActorCondition { store.state.itemsForm[itemId] == nil && didUnloadCalled }
                #expect(success)
            }
        }

        window?.release()
        window = nil
        window?.redraw()
    }

    @MainActor
    @Test("Verify if rapid unload of multiple containers with same ID within 0.15s behaves correctly or fails due to delay race condition")
    func rapidUnloadRaceCondition() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        let itemId = Item.ID(value: 1)
        
        let manager = TestStateViewModel()
        let root = TestStateView(manager: manager)
        var window: PlatformWindow? = await PlatformWindow.render(view: root)
        
        var didLoadCalled = false
        var didUnloadCalled = false

        await confirmation("didLoad", expectedCount: 1) { confirmLoad in
            await confirmation("didUnload", expectedCount: 1) { confirmUnload in
                // 1. Load first container
                let container1 = ItemsContainer(
                    id: itemId,
                    onBindableReducerDidLoad: {
                        didLoadCalled = true
                        confirmLoad()
                    },
                    onBindableReducerDidUnload: {
                        didUnloadCalled = true
                        confirmUnload()
                    }
                )
                manager.containers = [.init(container: container1, isVisible: true)]
                window?.redraw()

                // Wait for the state to load and callback to fire
                var success = await waitForMainActorCondition { store.state.itemsForm[itemId] != nil && didLoadCalled }
                #expect(success)

                // 2. Load second container
                let container2 = ItemsContainer(
                    id: itemId,
                    onBindableReducerDidLoad: {
                        confirmLoad()
                    },
                    onBindableReducerDidUnload: {
                        didUnloadCalled = true
                        confirmUnload()
                    }
                )
                manager.containers.append(.init(container: container2, isVisible: true))
                window?.redraw()
                
                // Wait for the store to process the load action
                await sleep(for: 0.1)

                // 3. Rapidly unload both containers in the same run loop cycle
                manager.containers[0].isVisible = false
                manager.containers[1].isVisible = false
                window?.redraw()

                // Wait for the state to unload completely and callback to fire
                success = await waitForMainActorCondition { store.state.itemsForm[itemId] == nil && didUnloadCalled }
                #expect(success)
            }
        }

        window?.release()
        window = nil
        window?.redraw()
    }

    @MainActor
    @Test("onBindableReducerDidLoad and onBindableReducerDidUnload behave independently for different container IDs")
    func multipleContainersWithDifferentIDs() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        let itemId1 = Item.ID(value: 1)
        let itemId2 = Item.ID(value: 2)
        
        let manager = TestStateViewModel()
        let root = TestStateView(manager: manager)
        var window: PlatformWindow? = await PlatformWindow.render(view: root)
        
        var didLoad1Called = false
        var didLoad2Called = false
        var didUnload1Called = false
        var didUnload2Called = false

        await confirmation("didLoadItem1", expectedCount: 1) { confirmLoad1 in
            await confirmation("didUnloadItem1", expectedCount: 1) { confirmUnload1 in
                await confirmation("didLoadItem2", expectedCount: 1) { confirmLoad2 in
                    await confirmation("didUnloadItem2", expectedCount: 1) { confirmUnload2 in
                        let container1 = ItemsContainer(
                            id: itemId1,
                            onBindableReducerDidLoad: {
                                didLoad1Called = true
                                confirmLoad1()
                            },
                            onBindableReducerDidUnload: {
                                didUnload1Called = true
                                confirmUnload1()
                            }
                        )
                        let container2 = ItemsContainer(
                            id: itemId2,
                            onBindableReducerDidLoad: {
                                didLoad2Called = true
                                confirmLoad2()
                            },
                            onBindableReducerDidUnload: {
                                didUnload2Called = true
                                confirmUnload2()
                            }
                        )

                        // Load both
                        manager.containers = [
                            .init(container: container1, isVisible: true),
                            .init(container: container2, isVisible: true)
                        ]
                        window?.redraw()

                        // Wait for both states to load and callbacks to fire
                        let success = await waitForMainActorCondition {
                            store.state.itemsForm[itemId1] != nil &&
                            store.state.itemsForm[itemId2] != nil &&
                            didLoad1Called &&
                            didLoad2Called
                        }
                        #expect(success)

                        // Unload first
                        manager.containers[0].isVisible = false
                        window?.redraw()

                        // Wait for first state to unload and callback to fire
                        let success1 = await waitForMainActorCondition { store.state.itemsForm[itemId1] == nil && didUnload1Called }
                        #expect(success1)

                        // Unload second
                        manager.containers[1].isVisible = false
                        window?.redraw()

                        // Wait for second state to unload and callback to fire
                        let success2 = await waitForMainActorCondition { store.state.itemsForm[itemId2] == nil && didUnload2Called }
                        #expect(success2)
                    }
                }
            }
        }

        window?.release()
        window = nil
        window?.redraw()
    }

    @MainActor
    @Test("onBindableReducerDidLoad fires once, and onBindableReducerDidUnload is called when all 5 containers are rapidly unloaded simultaneously")
    func fiveContainersSimultaneousUnload() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        let itemId = Item.ID(value: 1)
        
        let manager = TestStateViewModel()
        let root = TestStateView(manager: manager)
        var window: PlatformWindow? = await PlatformWindow.render(view: root)
        
        var didLoadCalled = false
        var lastUnloadedContainerIndex: Int? = nil

        await confirmation("didLoad", expectedCount: 1) { confirmLoad in
            await confirmation("didUnload", expectedCount: 1) { confirmUnload in
                var containers: [ItemsContainer] = []
                for index in 0..<5 {
                    let container = ItemsContainer(
                        id: itemId,
                        onBindableReducerDidLoad: {
                            if !didLoadCalled {
                                didLoadCalled = true
                                confirmLoad()
                            }
                        },
                        onBindableReducerDidUnload: {
                            lastUnloadedContainerIndex = index
                            confirmUnload()
                        }
                    )
                    containers.append(container)
                }

                // Load all 5 containers
                manager.containers = containers.map { .init(container: $0, isVisible: true) }
                window?.redraw()

                // Wait for the state to load and callback to fire
                var success = await waitForMainActorCondition { store.state.itemsForm[itemId] != nil && didLoadCalled }
                #expect(success)

                // Rapidly unload all 5 containers in the same run loop cycle
                for i in 0..<5 {
                    manager.containers[i].isVisible = false
                }
                window?.redraw()

                // Wait for the state to unload completely and callback to fire (which is when the last/5th container invokes its handler)
                success = await waitForMainActorCondition { store.state.itemsForm[itemId] == nil && lastUnloadedContainerIndex != nil }
                #expect(success)
                
                // Assert that the last deallocated container was indeed the one that triggered the lifecycle call
                // Since they disappear in sequence from index 0 to 4 in ForEach, index 4 (the 5th container) is the last one deallocated.
                #expect(lastUnloadedContainerIndex == 4)
            }
        }

        window?.release()
        window = nil
        window?.redraw()
    }

    @MainActor
    @Test("Containers with the same ID on different stores have isolated active container counts")
    func multipleStoresWithSameContainerAndIDIsolatesCounts() async throws {
        let storeA = EnvironmentStore(initial: AppState(), loggers: [])
        let storeB = EnvironmentStore(initial: AppState(), loggers: [])
        let itemId = Item.ID(value: 99)

        let containerA = ItemsContainer(id: itemId)
        let containerB = ItemsContainer(id: itemId)

        struct TestView: View {
            let containerA: ItemsContainer
            let containerB: ItemsContainer
            let storeA: EnvironmentStore<AppState>
            let storeB: EnvironmentStore<AppState>

            var body: some View {
                VStack {
                    containerA.with(store: storeA)
                    containerB.with(store: storeB)
                }
            }
        }

        let root = TestView(
            containerA: containerA,
            containerB: containerB,
            storeA: storeA,
            storeB: storeB
        )

        var window: PlatformWindow? = await PlatformWindow.render(view: root)
        window?.redraw()

        // Wait for both stores to load the state for itemId
        let loaded = await waitForMainActorCondition {
            storeA.state.itemsForm[itemId] != nil &&
            storeB.state.itemsForm[itemId] != nil
        }
        #expect(loaded)

        // Get the active keys
        let keys = BaseContainerLifecycle.activeContainersCount.keys
        let matchingKeys = keys.filter { $0.id == AnyHashable(itemId) }

        // There should be exactly 2 distinct keys in the active count dictionary (one for each store)
        #expect(matchingKeys.count == 2)

        window?.release()
        window = nil
        window?.redraw()
    }
}

private extension BindableContainerLifecycleTests {
    @MainActor
    class TestStateViewModel: ObservableObject {
        struct ContainerItem: Identifiable {
            var id = UUID()
            let container: ItemsContainer
            var isVisible: Bool
        }

        @Published var containers: [ContainerItem] = []
    }

    struct TestStateView: View {
        @ObservedObject var manager: TestStateViewModel

        var body: some View {
            VStack {
                ForEach(manager.containers) { item in
                    if item.isVisible {
                        item.container
                    }
                }
            }
        }
    }
}

// MARK: Container
private extension BindableContainerLifecycleTests {
    struct ItemsContainer: BindableContainer {
        typealias ContainerComponent = ItemsComponent

        var id: Item.ID
        var onBindableReducerDidLoad: (@MainActor () -> Void)? = nil
        var onBindableReducerDidUnload: (@MainActor () -> Void)? = nil

        func scope(for state: AppState) -> Scope {
            state.itemsForm[id]
        }

        func map(store: EnvironmentStore<AppState>) -> ItemsComponent.Props {
            .init()
        }

        func onBindableReducerDidLoad(store: EnvironmentStore<AppState>) {
            self.onBindableReducerDidLoad?()
        }

        func onBindableReducerDidUnload(store: EnvironmentStore<AppState>) {
            self.onBindableReducerDidUnload?()
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
