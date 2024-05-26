
import XCTest
@testable import UDF
import Combine

fileprivate extension Actions {
    struct SendMessage: Action {
        var message: String
    }
}

final class NewReducibleMiddlewareTests: XCTestCase {
    
    struct AppState: AppReducer {
        var testForm = TestForm()
    }

    struct TestForm: Form {
        var title: String = ""
    }

    class SendMessageMiddleware: BaseReducibleMiddleware<AppState> {
        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }
        
        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }
        
        var environment: Environment!
        
        struct Environment {
            var loadItems: () -> [String]
        }

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.SendMessage:
                execute(
                    ServiceEffect(title: action.message)
                        .delay(duration: 0.2, queue: queue),
                    cancellation: "service"
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
        await store.wait()

        formTitle = await store.state.testForm.title
        XCTAssertEqual(formTitle, "Message 1")
    }
}
