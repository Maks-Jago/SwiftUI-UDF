import Testing
import SwiftUI
@testable import UDF
@testable import UDFModularizationTestFeature
import UDFSwiftTesting


struct FeatureRoutingTests {
    @MainActor
    @Test("Loads and observes a single item in the details view")
    func testSingleDetailsViewLoadsItem() async {
        let store = EnvironmentStore(initial: AppState(), logger: .consoleDebug)
        let testAppContext = TestAppContext(store: store)
        let testItemID: TestItem.ID = 1

        let detailsView = TestDetailsFeatureState<AppState>.entryPoint(input: testItemID)
            .environment(testAppContext)

        let window: PlatformWindow? = await PlatformWindow.render(view: detailsView)
        window?.redraw()

        let isLoadedItem = await waitForMainActorCondition {
            store.state.testDetailsFeatureState.form.testItem?.id == testItemID && store.state.testDetailsFeatureState.flow == .none
        }

        #expect(isLoadedItem)
        #expect(store.state.testDetailsFeatureState.form.testItem?.title == "Test item")
    }
    
    @MainActor
    @Test("Test home view inject list view throught Feature routing & list view dispatches Actions.LoadPage")
    func testHomeRoutingExecutesLoadActions() async {
        let store = EnvironmentStore(initial: AppState(), logger: .consoleDebug)
        let testAppContext = TestAppContext(store: store)
        
        let rootView = TestHomeFeatureState<AppState, TestHomeRouting>.entryPoint(input: ()).environment(testAppContext)
        
        let window: PlatformWindow? = await PlatformWindow.render(view: rootView)
        window?.redraw()

        let isLoadedItems = await waitForMainActorCondition {
            !store.state.testFeatureState.form.paginator.items.isEmpty && store.state.testFeatureState.flow == .none
        }
        #expect(isLoadedItems, "Test items should be delivered to form")
    }
    
    @MainActor
    @Test("Loads the routed item details through the navigation stack bounds")
    func testNavigationStackWithTestItemDetails() async {
        let store = EnvironmentStore(initial: AppState(), logger: .consoleDebug)
        let testAppContext = TestAppContext(store: store)
        
        let testItemID: TestItem.ID = 1
        let path = NavigationPath([TestHomeRoute.datails(testItemID)])
        let rootView = NavigationStackBound(path: .constant(path)) {
            TestHomeFeatureState<AppState, TestHomeRouting>.entryPoint(input: ())
                .modifier(GlobalRoutingModifier(routing: TestHomeRouting.self))
        }
        .environment(testAppContext)
        
        let window: PlatformWindow? = await PlatformWindow.render(view: rootView)
        window?.redraw()
        
        let isLoadedItem = await waitForMainActorCondition {
            store.state.testDetailsFeatureState.form.testItem != nil && store.state.testDetailsFeatureState.flow == .none
        }
        #expect(isLoadedItem, "Test items should be delivered to form")
    }
}

// MARK: - App Layer Space

@Observable private class TestAppContext {
    fileprivate var store: EnvironmentStore<AppState>
    
    fileprivate init(store: EnvironmentStore<AppState>) {
        self.store = store
    }
}

private struct TestHomeRouting: Routing {
    @ViewBuilder
    func view(for route: TestHomeRoute) -> some View {
        switch route {
        case .list:
            TestListItemsFeatureState<AppState>.entryPoint(input: ())
        case .datails(let detailsID):
            TestDetailsFeatureState<AppState>.entryPoint(input: detailsID)
        }
    }
}

private struct AppState: AppReducer, TestFeature, TestDetailsFeature, TestHomeFeature {
    typealias Environments = GlobalEnvironments

    // MARK: - Test Storage
    var allTestItems = AllTestItemsStorage()
    
    // MARK: - Feature States
    var testFeatureState = TestFeatureState<Self>()
    var testDetailsFeatureState = TestDetailsFeatureState<Self>()
    var testHomeFeatureState = TestHomeFeatureState<Self, TestHomeRouting>()
}

struct AllTestItemsStorage: Storage<TestItem> {
    var byId: [TestItem.ID: TestItem] = [:]
}


private enum GlobalEnvironments: TestEnvironmentProviding, TestDetailsEnvironmentProviding {
    static let testDetailsFeature = TestDetailsEnvironment.test()
    static let testFeature = TestEnvironment.test()
}

// MARK: - ListItems Feature Space

struct TestListItemsFeatureState<AppState: TestFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting
    typealias Input = Void

    var form = TestForm()
    var flow = TestFlow()

    init() {}

    static func entryPoint(input: Input) -> some View {
        TestListItemsDestination<AppState>(items: [])
    }

    static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
        TestMiddleware<AppState>.self
    }
}

struct TestListItemsDestination<AppState: TestFeature>: View {
    let items: [TestItem]
    @Environment(TestAppContext.self) fileprivate var context
    
    nonisolated init(items: [TestItem]) {
        self.items = items
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(items) { item in
                    Text(item.title)
                        .id(item.id)
                }
            }
        }
        .task {
            context.store.dispatch(Actions.LoadPage(id: TestFlow.id))
        }
    }
}

// MARK: - TestHome Feature Space

protocol TestHomeFeature: AppReducer {
    associatedtype TestHomeFeatureRouting: Routing<TestHomeRoute>
    
    var testHomeFeatureState: TestHomeFeatureState<Self, TestHomeFeatureRouting> { get }
}

struct TestHomeFeatureState<AppState: TestHomeFeature, FeatureRouting: Routing<TestHomeRoute>>: @preconcurrency FeatureState {
    typealias Input = Void
    init() {}
    
    @MainActor static func entryPoint(input: Input) -> some View {
        TestHomeFeatureDestination<AppState, FeatureRouting>(
            routing: FeatureRouting()
        )
    }
}

enum TestHomeRoute: Hashable {
    case list
    case datails(TestItem.ID)
}

struct TestHomeFeatureDestination<AppState: TestHomeFeature, R: Routing<TestHomeRoute>>: View {
    @Environment(TestAppContext.self) fileprivate var context
    var routing: R
    
    var body: some View {
        routing.view(for: .list)
    }
}

// MARK: - TestDetails Feature Space

struct TestDetailsEnvironment: Sendable {
    public var loadItem: @Sendable (TestItem.ID) async throws -> TestItem

    public init(
        loadItem: @escaping @Sendable (TestItem.ID) async throws -> TestItem
    ) {
        self.loadItem = loadItem
    }
}

extension TestDetailsEnvironment {
    static func test(
        loadItem: @escaping @Sendable (TestItem.ID) async throws -> TestItem = { testItemID in
            return TestItem(id: 1, title: "Test item")
        }) -> Self {
        
        Self(loadItem: loadItem)
    }
}

protocol TestDetailsEnvironmentProviding {
    static var testDetailsFeature: TestDetailsEnvironment { get }
}


protocol TestDetailsFeature: AppReducer {
    associatedtype Environments: TestDetailsEnvironmentProviding
    var testDetailsFeatureState: TestDetailsFeatureState<Self> { get }
}

struct TestDetailsFeatureState<AppState: TestDetailsFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting
    
    var form = TestDetailsForm()
    var flow = TestDetailsFlow()
    
    init() { }
    
    static func entryPoint(input: TestItem.ID) -> some View {
        TestDetailsDestination(id: input)
    }

    static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
        TestDetailsMiddleware<AppState>.self
    }
}

struct TestDetailsForm: UDF.Form {
    var testItem: TestItem?
    
    init() {}
    
    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidLoadItem<TestItem>:
            self.testItem = action.item
        default:
            break
        }
    }
}

enum TestDetailsFlow: UDF.IdentifiableFlow {
    case none
    case loading(TestItem.ID)
    
    init() { self = .none }
    
    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.LoadTestDetails where action.id == Self.id:
            self = .loading(action.testItemID)
        case let action as Actions.DidLoadItem<TestItem> where action.id == Self.id:
            self = .none
        case let action as Actions.DidCancelEffect where action.cancellation == AnyHashable(TestDetailsMiddlewareCancellation.loadItem):
            self = .none
        default:
            break
        }
    }
}

struct TestDetailsDestination: View {
    @Environment(TestAppContext.self) fileprivate var context
    var item: TestItem?
    private let id: TestItem.ID?
    
    nonisolated init(id: TestItem.ID? = nil) {
        self.item = nil
        self.id = id
    }
    
    var body: some View {
        ZStack {
            if let item {
                VStack {
                    Text(item.title)
                }
            }
        }
        .task {
            if let id {
                context.store.dispatch(
                    Actions.LoadTestDetails(id: TestDetailsFlow.id, testItemID: id)
                )
            }
        }
    }
}

enum TestDetailsMiddlewareCancellation: Hashable, Sendable {
    case loadItem
}

final class TestDetailsMiddleware<AppState: TestDetailsFeature>: Middleware<AppState>, @unchecked Sendable {
    var environment: TestDetailsEnvironment!

    static func buildLiveEnvironment(for store: some Store<AppState>) -> TestDetailsEnvironment {
        AppState.Environments.testDetailsFeature
    }

    static func buildTestEnvironment(for store: some Store<AppState>) -> TestDetailsEnvironment {
        AppState.Environments.testDetailsFeature
    }

    func scope(for state: AppState) -> Scope {
        state.testDetailsFeatureState.flow
    }

    func observe(state: AppState) {
        switch state.testDetailsFeatureState.flow {
        case let .loading(testID):
            execute(
                flowId: TestDetailsFlow.id,
                cancellation: TestDetailsMiddlewareCancellation.loadItem
            ) { [unowned self] flowID in
                let testItem = try await self.environment.loadItem(testID)
                return Actions.DidLoadItem(item: testItem, id: TestDetailsFlow.id)
            }
        default:
            break
        }
    }
}

private extension Actions {
    struct LoadTestDetails: Action {
        let id: AnyHashable
        let testItemID: TestItem.ID
    }
}
