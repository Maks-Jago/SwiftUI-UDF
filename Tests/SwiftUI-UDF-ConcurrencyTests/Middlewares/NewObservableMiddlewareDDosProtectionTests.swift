import Combine
@testable import UDF
import UDFSwiftTesting
import Testing

private extension Actions {
    struct SendMessage: Action {
        var message: String
        var id: AnyHashable? = nil
    }
}

@Suite struct NewObservableMiddlewareDDosProtectionTests {
    struct AppState: AppReducer {
        var testForm = TestForm()
        var testFlow = TestFlow()
    }

    struct TestForm: Form {
        var title: String = ""

        var nested: NestedForm = .init()
    }

    struct NestedForm: Form {
        var number: Int = 0
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

    class SendMessageMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment {}

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        func scope(for state: AppState) -> Scope {
            state.testFlow
            state.testForm
        }

        var observeCount = 0

        func observe(state: AppState) {
            observeCount += 1

            switch state.testFlow {
            case let .sending(message):
                execute(ServiceEffect(title: message, number: observeCount), cancellation: "service")

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

    @Test func observableMiddlewareDDDos() async {
        let store = EnvironmentStore(initial: AppState(), loggers: [])

        store.subscribe(SendMessageMiddleware.self)

        var formTitle = store.state.testForm.title
        #expect(formTitle.isEmpty)

        store.dispatch(Actions.SendMessage(message: "Flow message 1", id: TestFlow.id))
        await waitForCondition {
            store.state.testForm.title == "Flow message 1"
        }
        store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title"))
        await waitForCondition {
            store.state.testForm.title == "title"
        }
        store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title2"))
        await waitForCondition {
            store.state.testForm.title == "title2"
        }
        store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title3"))
        await waitForCondition {
            store.state.testForm.title == "title3"
        }
        store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title4"))
        await waitForCondition {
            store.state.testForm.title == "title4"
        }
        
        // Wait for middleware to process and set nested.number to 2
        await waitForCondition {
            store.state.testForm.nested.number == 2
        }

        let numberValue = store.state.testForm.nested.number
        #expect(numberValue == 2)

        formTitle = store.state.testForm.title
        #expect(formTitle == "title4")

        store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title5"))
        await waitForCondition {
            store.state.testForm.title == "title5"
        }
        
        store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title6"))
        await waitForCondition {
            store.state.testForm.title == "title6"
        }

        formTitle = store.state.testForm.title
        #expect(formTitle == "title6")
    }
}
