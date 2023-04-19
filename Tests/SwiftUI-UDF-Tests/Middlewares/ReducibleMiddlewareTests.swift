
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

    struct ConsoleLogger: ActionLogger {
        func log(_ action: LoggingAction) {
            print(action)
        }
    }

    struct AppState: AppReducer {
        var testForm = TestForm()
        var testFlow = TestFlow()

        var formToCombine = FormToCombine()
    }

    struct TestForm: Form {
        var title: String = ""

        var nested: NestedForm = .init()
    }

    struct NestedForm: Form {
        var number: Int = 0
    }

    struct FormToCombine: Form {
        var value: Int = 0
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
                execute(ServiceEffect(title: action.message), cancelation: "service")

            default:
                break
            }
        }
    }

    class ServiceObservableMiddleware: BaseObservableMiddleware<AppState> {
        struct Environment {

        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        func scope(for state: ReducibleMiddlewareTests.AppState) -> Scope {
            Scopes {
                state.testFlow
                state.testForm
                state.formToCombine
            }
        }

        func observe(state: AppState) {
            switch state.testFlow {
            case .sending(let message):
                execute(ServiceEffect(title: message), cancelation: "service")

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

    func testReducibleMiddleware() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.subscribe(ServiceMiddleware.self)
        await store.subscribe(ServiceObservableMiddleware.self)

        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title 1"))

        var title = await store.state.testForm.title
        XCTAssertEqual(title, "title 1")

        await store.dispatch(Actions.SendMessage(message: "Service title 1"))
        await expectation(description: "exp", sleep: 1)

        title = await store.state.testForm.title

        XCTAssertEqual(title, "Service title 1")

        await store.dispatch(Actions.SendMessage(message: "Flow message", id: TestFlow.id))
        await store.dispatch(Actions.UpdateFormField(keyPath: \FormToCombine.value, value: 2))

        await expectation(description: "flowExp", sleep: 1)

        title = await store.state.testForm.title
        XCTAssertEqual(title, "Flow message")
    }
}
