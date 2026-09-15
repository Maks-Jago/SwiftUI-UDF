import SwiftUI
import UDF

// MARK: - Public feature integration surface

public struct TestItem: StorageItem, Hashable {
    public let id: Int
    public let title: String

    public init(id: Int, title: String) {
        self.id = id
        self.title = title
    }

    public static let empty = Self(id: -1, title: "")
}

public struct TestEnvironment: Sendable {
    public var loadItems: @Sendable (_ page: Int) async throws -> [TestItem]

    public init(
        loadItems: @escaping @Sendable (_ page: Int) async throws -> [TestItem]
    ) {
        self.loadItems = loadItems
    }
}

public extension TestEnvironment {
    static func test(
        loadItems: @escaping @Sendable (_ page: Int) async throws -> [TestItem] = { page in
            let firstID = ((page - 1) * 2) + 1
            return [
                TestItem(id: firstID, title: "Test item \(firstID)"),
                TestItem(id: firstID + 1, title: "Test item \(firstID + 1)"),
            ]
        }
    ) -> Self {
        Self(loadItems: loadItems)
    }
}

public protocol TestEnvironmentProviding {
    static var testFeature: TestEnvironment { get }
}

public protocol TestFeature: AppReducer {
    associatedtype Environments: TestEnvironmentProviding
    associatedtype TestItemsStorage: Storage<TestItem>

    var allTestItems: TestItemsStorage { get }
    var testFeature: TestFeatureState<Self> { get }
}

public struct TestFeatureInput: Equatable, Sendable {
    public let title: String

    public init(title: String) {
        self.title = title
    }
}

public struct TestFeatureDestination: View {
    public nonisolated let input: TestFeatureInput

    public nonisolated init(input: TestFeatureInput) {
        self.input = input
    }

    public var body: some View {
        Text(input.title)
    }
}

public struct TestFeatureState<AppState: TestFeature>: FeatureState {
    public var form = TestForm()
    public var flow = TestFlow()

    public init() {}

    public static func entryPoint(
        input: TestFeatureInput
    ) -> TestFeatureDestination {
        .init(input: input)
    }

    public static func registerMiddlewares(
        in store: any Store<AppState>
    ) -> [MiddlewareWrapper<AppState>] {
        TestMiddleware<AppState>.self
    }
}

// MARK: - Internal feature implementation

public enum TestMiddlewareCancellation: Hashable, Sendable {
    case loadItems
}

public struct TestForm: UDF.Form, Equatable {
    public var paginator = Paginator(
        TestItem.self,
        flowId: TestFlow.id,
        perPage: 2
    )

    public init() {}

    public mutating func reduce(_ action: some Action) {}
}

public enum TestFlow: IdentifiableFlow, Equatable {
    case none
    case loading(Int)

    public init() {
        self = .none
    }

    public mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.LoadPage where action.id == Self.id:
            self = .loading(action.pageNumber)

        case let action as Actions.DidLoadItems<TestItem>
            where action.id == Self.id:
            self = .none

        case let action as Actions.DidLoadItem<TestItem>
            where action.id == Self.id:
            self = .none

        case let action as Actions.Error where action.id == Self.id:
            self = .none

        case let action as Actions.DidCancelEffect
            where action.cancellation == AnyHashable(TestMiddlewareCancellation.loadItems):
            self = .none

        default:
            break
        }
    }
}

final class TestMiddleware<AppState: TestFeature>:
    Middleware<AppState>,
    @unchecked Sendable
{
    typealias Environment = TestEnvironment

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
        AppState.Environments.testFeature
    }

    static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
        .test()
    }

    func scope(for state: AppState) -> Scope {
        state.testFeature.flow
    }

    func observe(state: AppState) {
        switch state.testFeature.flow {
        case let .loading(page):
            execute(
                flowId: TestFlow.id,
                cancellation: TestMiddlewareCancellation.loadItems
            ) { [unowned self] flowID in
                guard case let .loading(currentPage) = state.testFeature.flow, currentPage == page else {
                    throw CancellationError()
                }

                let items = try await self.environment.loadItems(page)
                return Actions.DidLoadItems(items: items, id: flowID)
            }

        default:
            break
        }
    }
}

// MARK: - Settings-style empty feature

public protocol TestSettingsFeature: AppReducer {
    var testSettings: TestSettingsFeatureState<Self> { get }
}

public struct TestSettingsInput: Equatable, Sendable {
    public let title: String

    public init(title: String) {
        self.title = title
    }
}

public struct TestSettingsDestination: View {
    public nonisolated let input: TestSettingsInput

    public nonisolated init(input: TestSettingsInput) {
        self.input = input
    }

    public var body: some View {
        Text(input.title)
    }
}

public struct TestSettingsFeatureState<AppState: TestSettingsFeature>:
    FeatureState
{
    public init() {}

    public static func entryPoint(
        input: TestSettingsInput
    ) -> TestSettingsDestination {
        .init(input: input)
    }
}
