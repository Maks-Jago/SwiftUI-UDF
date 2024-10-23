
import Combine
@testable import UDF
import UDFXCTest
import XCTest

private extension Actions {
    struct StartLoading: Action {}
}

final class MiddlewareMapErrorTests: XCTestCase {
    struct AppState: AppReducer {
        var errorForm = ErrorForm()

        struct ErrorForm: Form {
            var errorStatusCode = -1

            mutating func reduce(_ action: some Action) {
                switch action {
                case let error as Actions.Error:
                    errorStatusCode = error.code
                default:
                    break
                }
            }
        }

        enum ErrorFlow: IdentifiableFlow {
            case none
            init() { self = .none }
        }
    }

    enum APIError: LocalizedError {
        case statusCode(Int)
    }

    final class LoadingMiddleware: BaseReducibleMiddleware<AppState> {
        enum Сancellation: CaseIterable {
            case message
        }

        var environment: Void!

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case is Actions.StartLoading:
                execute(
                    flowId: MiddlewareMapErrorTests.AppState.ErrorFlow.id,
                    cancellation: Сancellation.message,
                    mapError: mapAPIError
                ) { _ in
                    throw APIError.statusCode(400)
                }

            default:
                break
            }
        }

        func mapAPIError(_ id: some Hashable, _ error: Error) -> any Action {
            switch error {
            case let error as APIError:
                switch error {
                case let .statusCode(code):
                    Actions.Error(error: error.localizedDescription, id: id, code: code)
                }

            default:
                Actions.Error(error: error.localizedDescription, id: id)
            }
        }
    }

    func testMapError() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(LoadingMiddleware.self)

        await store.dispatch(Actions.StartLoading())
        await store.wait()

        let statusCode = await store.state.errorForm.errorStatusCode
        XCTAssertEqual(statusCode, 400)
    }
}
