
import XCTest
@testable import UDF
import Combine

fileprivate extension Actions {
    struct SendMessage: Action {
        var message: String
        var id: AnyHashable? = nil
    }
}

class ObservableMiddlewareTests: XCTestCase {

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

    class SendMessageMiddleware: BaseObservableMiddleware<AppState> {
        struct Environment {

        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }


        func scope(for state: ObservableMiddlewareTests.AppState) -> Scope {
            Scopes {
                state.testFlow
                state.testForm
            }
        }

        var observeCount = 0

        func observe(state: AppState) {
            observeCount += 1
            print("observeCount: \(observeCount)")

            switch state.testFlow {
            case .sending(let message):
                execute(ServiceEffect(title: message, number: 4), cancelation: "service")

            default:
                break
            }
        }
    }

    struct ServiceEffect: Effectable {
        var title: String
        var number: Int

        var upstream: AnyPublisher<any Action, Never> {
            Just(
                ActionGroup {
                    Actions.UpdateFormField(keyPath: \TestForm.title, value: title)
                    Actions.UpdateFormField(keyPath: \NestedForm.number, value: number)
                }
            )
            .eraseToAnyPublisher()
        }
    }

    func testObservableMiddlewareOnceCalling() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.subscribe(SendMessageMiddleware.self)

        await store.dispatch(Actions.SendMessage(message: "Flow message 1", id: TestFlow.id))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title2"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title3"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title4"))

        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title5"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title6"))

        await expectation(description: "flowExp", sleep: 3)

        let number = await store.state.testForm.nested.number
        XCTAssertGreaterThan(number, 1)
    }
}
