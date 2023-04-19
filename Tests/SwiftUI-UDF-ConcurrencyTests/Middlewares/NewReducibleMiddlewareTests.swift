
import XCTest
@testable import UDF
import Combine

fileprivate extension Actions {
    struct SendMessage: Action {
        var message: String
    }
}

final class NewReducibleMiddlewareTests: XCTestCase {

    struct ConsoleLogger: ActionLogger {
        func log(_ action: LoggingAction) {
            print(action)
        }
    }

    struct AppState: AppReducer {
        var testForm = TestForm()
    }

    struct TestForm: Form {
        var title: String = ""
    }

    class SendMessageMiddleware: BaseReducibleMiddleware<AppState> {
        var environment: Void!

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.SendMessage:
                execute(
                    ServiceEffect(title: action.message)
                        .delay(duration: 0.2, queue: queue),
                    cancelation: "service"
                )

            default:
                break
            }
        }
    }

    struct ServiceEffect: Effectable {
        var title: String

        var upstream: AnyPublisher<any Action, Never> {
            Just(
                Actions.UpdateFormField(keyPath: \TestForm.title, value: title)
            )
            .eraseToAnyPublisher()
        }
    }

    func testReducibleMiddleware() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.subscribe(SendMessageMiddleware.self)

        var formTitle = await store.state.testForm.title
        XCTAssertTrue(formTitle.isEmpty)

        await store.dispatch(Actions.SendMessage(message: "Message 1"))
        await expectation(description: "Waiting for observe method", sleep: 0.5)

        formTitle = await store.state.testForm.title
        XCTAssertEqual(formTitle, "Message 1")
    }
}
