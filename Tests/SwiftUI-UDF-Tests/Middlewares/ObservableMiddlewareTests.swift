
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
            state.testFlow
            state.testForm
        }

        var observeCount = 0

        func observe(state: AppState) {
            observeCount += 1
            print("observeCount: \(observeCount)")

            switch state.testFlow {
            case .sending(let message):
                execute(ServiceEffect(title: message, number: 4), cancellation: "service")

            default:
                break
            }
        }
    }

    struct ServiceEffect: Effectable {
        var title: String
        var number: Int

        var upstream: AnyPublisher<any Action, Never> {
            Just(Actions.UpdateFormField(keyPath: \TestForm.title, value: title))
                .eraseToAnyPublisher()
        }
    }

    func testObservableMiddlewareOnceCalling() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(SendMessageMiddleware.self)

        let message = "Flow message 1"
        await store.dispatch(Actions.SendMessage(message: message, id: TestFlow.id))
        await store.wait()
        
        let title = await store.state.testForm.title
        XCTAssertEqual(title, message)
    }
}
