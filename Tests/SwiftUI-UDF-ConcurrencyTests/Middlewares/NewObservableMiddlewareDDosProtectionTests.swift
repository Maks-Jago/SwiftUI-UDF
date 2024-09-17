import XCTest
@testable import UDF
import Combine

fileprivate extension Actions {
    struct SendMessage: Action {
        var message: String
        var id: AnyHashable? = nil
    }
}

final class NewObservableMiddlewareDDosProtectionTests: XCTestCase {

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

        func scope(for state: AppState) -> Scope {
            state.testFlow
            state.testForm
        }

        var observeCount = 0

        func observe(state: AppState) {
            observeCount += 1

            switch state.testFlow {
            case .sending(let message):
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

    func testObservableMiddlewareDDDos() async {
        let store = await XCTestStore(initial: AppState())

        await store.subscribe(SendMessageMiddleware.self)
        await store.wait()

        var formTitle = await store.state.testForm.title
        XCTAssertTrue(formTitle.isEmpty)

        await store.dispatch(Actions.SendMessage(message: "Flow message 1", id: TestFlow.id))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title2"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title3"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title4"))
        await store.wait()

        let numberValue = await store.state.testForm.nested.number
        XCTAssertEqual(numberValue, 2)

        formTitle = await store.state.testForm.title
        XCTAssertEqual(formTitle, "title4")

        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title5"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title6"))
        await store.wait()

        formTitle = await store.state.testForm.title
        XCTAssertEqual(formTitle, "title6")
    }
}
