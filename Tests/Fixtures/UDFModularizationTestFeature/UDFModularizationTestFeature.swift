import SwiftUI
import UDF

// MARK: - Public feature integration surface

public struct ModularizationTestItem: StorageItem, Hashable {
    public let id: Int
    public let title: String

    public init(id: Int, title: String) {
        self.id = id
        self.title = title
    }

    public static let empty = Self(id: -1, title: "")
}

public struct ModularizationTestEnvironment: Sendable {
    public var loadItems: @Sendable (_ page: Int) async throws -> [ModularizationTestItem]

    public init(
        loadItems: @escaping @Sendable (_ page: Int) async throws -> [ModularizationTestItem]
    ) {
        self.loadItems = loadItems
    }
}

public protocol ModularizationTestEnvironmentProviding {
    static var modularizationTestFeature: ModularizationTestEnvironment { get }
}

public protocol ModularizationTestFeature: AppReducer {
    associatedtype Environments: ModularizationTestEnvironmentProviding
    associatedtype ModularizationTestItemsStorage: Storage<ModularizationTestItem>

    var allModularizationTestItems: ModularizationTestItemsStorage { get }
    var modularizationTestFeature: ModularizationTestFeatureState<Self> { get }
}

public struct ModularizationTestFeatureInput: Equatable, Sendable {
    public let title: String

    public init(title: String) {
        self.title = title
    }
}

public struct ModularizationTestFeatureDestination: View {
    nonisolated public let input: ModularizationTestFeatureInput

    nonisolated public init(input: ModularizationTestFeatureInput) {
        self.input = input
    }

    public var body: some View {
        Text(input.title)
    }
}

public struct ModularizationTestFeatureState<AppState: ModularizationTestFeature>: FeatureState {
    public var form = ModularizationTestForm()
    public var flow = ModularizationTestFlow()

    public init() {}

    public static func entryPoint(
        input: ModularizationTestFeatureInput
    ) -> ModularizationTestFeatureDestination {
        .init(input: input)
    }

    public static func registerMiddlewares(
        in store: any Store<AppState>
    ) -> [MiddlewareWrapper<AppState>] {
        ModularizationTestMiddleware<AppState>(
            store: store,
            environment: AppState.Environments.modularizationTestFeature
        )
    }
}

// MARK: - Internal feature implementation

public enum ModularizationTestMiddlewareCancellation: Hashable, Sendable {
    case loadItems
}

public struct ModularizationTestForm: UDF.Form, Equatable {
    public var paginator = Paginator(
        ModularizationTestItem.self,
        flowId: ModularizationTestFlow.id,
        perPage: 2
    )

    public init() {}

    public mutating func reduce(_ action: some Action) {}
}

public enum ModularizationTestFlow: IdentifiableFlow, Equatable {
    case none
    case loading(Int)

    public init() {
        self = .none
    }

    public mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.LoadPage where action.id == Self.id:
            self = .loading(action.pageNumber)

        case let action as Actions.DidLoadItems<ModularizationTestItem>
            where action.id == Self.id:
            self = .none

        case let action as Actions.DidLoadItem<ModularizationTestItem>
            where action.id == Self.id:
            self = .none

        case let action as Actions.Error where action.id == Self.id:
            self = .none

        case let action as Actions.DidCancelEffect
            where action.cancellation == AnyHashable(ModularizationTestMiddlewareCancellation.loadItems):
            self = .none

        default:
            break
        }
    }
}

private final class ModularizationTestMiddleware<AppState: ModularizationTestFeature>:
    FeatureMiddleware<AppState>,
    @unchecked Sendable
{
    typealias Environment = ModularizationTestEnvironment

    var environment: Environment!

    func scope(for state: AppState) -> Scope {
        state.modularizationTestFeature.flow
    }

    func observe(state: AppState) {
        switch state.modularizationTestFeature.flow {
        case let .loading(page):
            execute(
                flowId: ModularizationTestFlow.id,
                cancellation: ModularizationTestMiddlewareCancellation.loadItems
            ) { [unowned self] flowID in
                guard case let .loading(currentPage) = state.modularizationTestFeature.flow, currentPage == page else {
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

public protocol ModularizationTestSettingsFeature: AppReducer {
    var modularizationTestSettings: ModularizationTestSettingsFeatureState<Self> { get }
}

public struct ModularizationTestSettingsInput: Equatable, Sendable {
    public let title: String

    public init(title: String) {
        self.title = title
    }
}

public struct ModularizationTestSettingsDestination: View {
    nonisolated public let input: ModularizationTestSettingsInput

    nonisolated public init(input: ModularizationTestSettingsInput) {
        self.input = input
    }

    public var body: some View {
        Text(input.title)
    }
}

public struct ModularizationTestSettingsFeatureState<AppState: ModularizationTestSettingsFeature>:
    FeatureState
{
    public init() {}

    public static func entryPoint(
        input: ModularizationTestSettingsInput
    ) -> ModularizationTestSettingsDestination {
        .init(input: input)
    }
}
