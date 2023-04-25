
import XCTest
@testable import UDF
import Combine

final class ConcurrencyMiddlewareCancelationTests: XCTestCase {

    struct ConsoleLogger: ActionLogger {
        func log(_ action: LoggingAction) {
            print(action)
        }
    }

    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, cancel, message, didCancel

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidCancelEffect where action.cancelation == ObservableMiddlewareToCancel.Cancelation.message:
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

    func testObservableMiddlewareCancelation() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.subscribe(ObservableMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow

        XCTAssertEqual(middlewareFlow, .loading)
        await store.dispatch(Actions.CancelLoading())

        await expectation(description: "Waiting for cancelation", sleep: 0.2)

        middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .didCancel)
    }
}

fileprivate extension Actions {

    struct Loading: Action {}
    struct CancelLoading: Action {}
}

// MARK: - Middlewares
private extension ConcurrencyMiddlewareCancelationTests {

    final class ObservableMiddlewareToCancel: BaseConcurrencyObservableMiddleware<AppState> {
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

        enum Cancelation: CaseIterable {
            case message
        }

        func scope(for state: AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: AppState) {
            switch state.middlewareFlow {
            case .loading:
                execute(
                    SomeEffect(id: "message_id"),
                    cancelation: Cancelation.message
                )

            case .cancel:
                cancel(by: Cancelation.message)

            default:
                break
            }
        }


        struct SomeEffect<Id: Hashable>: ConcurrencyEffect {
            var id: Id

            func task() async throws -> any Action {
                try await Task.sleep(seconds: 1)

                try Task.checkCancellation()

                return Actions.Message(message: "Success message", id: id)
            }
        }
    }
}
