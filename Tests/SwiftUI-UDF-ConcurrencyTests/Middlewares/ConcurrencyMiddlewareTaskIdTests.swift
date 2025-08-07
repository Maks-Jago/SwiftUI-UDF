import Combine
import Testing
import UDFSwiftTesting
@testable import UDF

@Suite struct ConcurrencyMiddlewareTaskIdTests {
    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, didLoad

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.Loading:
                self = .loading

            case let action as Actions.DidFinishLoading where action.id == Self.id:
                self = .didLoad

            default:
                break
            }
        }
    }

    struct RunForm: Form {
        var loadedCount: Int = 0

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidFinishLoading where action.id == MiddlewareFlow.id:
                loadedCount += 1

            default:
                break
            }
        }
    }

    @Test func reducibleMiddlewareTaskId() async {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        store.subscribe(TestReducibleMiddleware.self)

        var runForm = store.state.runForm
        #expect(runForm.loadedCount == 0)

        store.dispatch(Actions.Loading(id: MiddlewareFlow.id))
        await fulfill(description: "waiting for middleware operations", sleep: 0.5)

        runForm = store.state.runForm
        #expect(runForm.loadedCount == 1)
    }
}

private extension Actions {
    struct Loading: Action {
        let id: AnyHashable
    }
    struct DidFinishLoading: Action {
        let id: AnyHashable
    }
}

// MARK: - Middlewares
private extension ConcurrencyMiddlewareTaskIdTests {
    final class TestReducibleMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment : Sendable{
            var loadItems: @Sendable () async -> [String]
        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }

        enum Cancellation: CaseIterable {
            case loading
        }

        func reduce(_ action: some Action, for state: ConcurrencyMiddlewareTaskIdTests.AppState) {
            switch action {
            case let action as Actions.Loading:
                execute(
                    effect: SomeEffect(),
                    flowId: action.id,
                    cancellation: Cancellation.loading
                )

            default:
                break
            }
        }

        struct SomeEffect: ConcurrencyEffect {
            func task(flowId: AnyHashable) async throws -> any Action {
                Actions.DidFinishLoading(id: flowId)
            }
        }
    }
}
