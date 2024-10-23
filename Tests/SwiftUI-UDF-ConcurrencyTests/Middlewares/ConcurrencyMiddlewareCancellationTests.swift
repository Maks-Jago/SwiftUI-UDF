
import Combine
@testable import UDF
import XCTest

final class ConcurrencyMiddlewareCancellationTests: XCTestCase {
    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, cancel, message, didCancel

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidCancelEffect where action.cancellation == ObservableMiddlewareToCancel.Сancellation.message:
                self = .didCancel

            case is Actions.Loading:
                self = .loading

            case is Actions.CancelLoading:
                self = .cancel

            case is Actions.Message:
                self = .message

            default:
                break
            }
        }
    }

    struct RunForm: Form {
        var messagesCount: Int = 0

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.Message:
                messagesCount += 1

            default:
                break
            }
        }
    }

    func testObservableMiddlewareCancellation() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(ObservableMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow

        XCTAssertEqual(middlewareFlow, .loading)
        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .didCancel)
    }
}

private extension Actions {
    struct Loading: Action {}
    struct CancelLoading: Action {}
}

// MARK: - Middlewares
private extension ConcurrencyMiddlewareCancellationTests {
    final class ObservableMiddlewareToCancel: BaseObservableMiddleware<AppState> {
        struct Environment {
            var loadItems: () async -> [String]
        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }

        enum Сancellation: CaseIterable {
            case message
        }

        func scope(for state: AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: AppState) {
            switch state.middlewareFlow {
            case .loading:
                execute(
                    effect: SomeEffect(),
                    flowId: "message_id",
                    cancellation: Сancellation.message
                )

            case .cancel:
                cancel(by: Сancellation.message)

            default:
                break
            }
        }

        struct SomeEffect: ConcurrencyEffect {
            func task(flowId: AnyHashable) async throws -> any UDF.Action {
                try await Task.sleep(seconds: 1)
                
                try Task.checkCancellation()
                
                return Actions.Message(message: "Success message", id: flowId)
            }
        }
    }
} 
