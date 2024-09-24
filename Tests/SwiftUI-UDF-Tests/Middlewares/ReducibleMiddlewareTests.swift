
import XCTest
@testable import UDF
import Combine

fileprivate extension Actions {
    struct SendMessage: Action {
        var message: String
        var id: AnyHashable? = nil
    }
}

class ReducibleMiddlewareTests: XCTestCase {

    struct AppState: AppReducer {
        var testForm = TestForm()
        var testFlow = TestFlow()
    }

    struct TestForm: Form {
        var title: String = ""
    }

    enum TestFlow: IdentifiableFlow {
        case none, sending(message: String)

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.SendMessage where action.id == Self.id:
                self = .sending(message: action.message)

            case let action as Actions.UpdateFormField<TestForm> where action.keyPath == \TestForm.title:
                self = .none

            default:
                break
            }
        }
    }

    class ServiceMiddleware: BaseReducibleMiddleware<AppState> {
        struct Environment {

        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        func reduce(_ action: some Action, for state: ReducibleMiddlewareTests.AppState) {
            switch action {
            case let action as Actions.SendMessage:
                execute(ServiceEffect(title: action.message), cancellation: "service")

            default:
                break
            }
        }
    }

    struct ServiceEffect: Effectable {
        var title: String

        var upstream: AnyPublisher<any Action, Never> {
            Just(Actions.UpdateFormField(keyPath: \TestForm.title, value: title))
                .eraseToAnyPublisher()
        }
    }

    func testReducibleMiddleware() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(ServiceMiddleware.self)

        let message = "Service title 1"
        await store.dispatch(Actions.SendMessage(message: message))
        await store.wait()

        let title = await store.state.testForm.title
        XCTAssertEqual(title, message)
    }
}
