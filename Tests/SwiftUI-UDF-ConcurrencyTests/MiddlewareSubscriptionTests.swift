import XCTest
@testable import UDF
import Combine

fileprivate extension Actions {
    struct TestMiddleware: Action {
        var type: MiddlewareSubscriptionTests.TestMiddlewareType
    }
}

final class MiddlewareSubscriptionTests: XCTestCase {
    
    @available(iOS 16.0.0, *)
    func testMiddlewareSubscriptions() async throws {
        let store = try await XCTestStore(initial: AppState())
        
        await store.subscribeAsync { store in
            ObservableMiddleware.self
            ReducibleMiddleware(store: store)
        }

        var type = await store.state.testForm.type
        XCTAssertNil(type)

        await store.dispatch(Actions.TestMiddleware(type: .observable))
        await store.wait()
        type = await store.state.testForm.type
        XCTAssertEqual(type, .observable)
        
        await store.dispatch(Actions.TestMiddleware(type: .reducible))
        await store.wait()
        type = await store.state.testForm.type
        XCTAssertEqual(type, .reducible)
    }
    
    @available(iOS 16.0.0, *)
    func testEnvironmentMiddlewareSubscription() async throws {
        let store = try await XCTestStore(initial: AppState())
        
        await store.subscribeAsync { store in
            EnvironmentMiddleware.self
        }

        let middlewareId = await store.state.testForm.type
        await store.wait()
        XCTAssertEqual(middlewareId, .testEnvironment)
    }
    
    @available(iOS 16.0.0, *)
    func liveEnvironmentMiddlewareSubscription() async throws {
        let store = try await XCTestStore(initial: AppState())
        
        setLiveEnvironment()
        
        await store.subscribeAsync { store in
            EnvironmentMiddleware.self
        }

        let middlewareId = await store.state.testForm.type
        await store.wait()
        XCTAssertEqual(middlewareId, .liveEnvironment)
    }
}

// MARK: - AppState
extension MiddlewareSubscriptionTests {
    
    enum TestMiddlewareType: String {
        case observable, reducible, testEnvironment, liveEnvironment
    }
    
    struct AppState: AppReducer {
        var testForm = TestForm()
        var testFlow = TestFlow()
    }
    
    enum TestFlow: IdentifiableFlow {
        case none, testing(TestMiddlewareType)
        
        init() { self = .none }
        
        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.TestMiddleware where action.type == .observable:
                self = .testing(action.type)
                
            default:
                break
            }
        }
    }
    
    struct TestForm: Form {
        var type: TestMiddlewareType? = nil
    }
}

//MARK: - Middlewares
extension MiddlewareSubscriptionTests {
    
    struct TestMiddlewareEffect: Effectable {
        var type: TestMiddlewareType

        var upstream: AnyPublisher<any Action, Never> {
            Just(
                Actions.UpdateFormField(keyPath: \TestForm.type, value: type)
            )
            .eraseToAnyPublisher()
        }
    }
    
    class ObservableMiddleware: BaseObservableMiddleware<AppState> {
        var environment: Void!
        
        func scope(for state: AppState) -> Scope {
            state.testFlow
        }
        
        func observe(state: AppState) {
            switch state.testFlow {
            case .testing(let middlewareType):
                execute(
                    TestMiddlewareEffect(type: middlewareType)
                        .delay(duration: 0.2, queue: queue),
                    cancelation: middlewareType.rawValue
                )
                
            default:
                break
            }
        }
    }
    
    class ReducibleMiddleware: BaseReducibleMiddleware<AppState> {
        var environment: Void!
        
        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.TestMiddleware where action.type == .reducible:
                execute(
                    TestMiddlewareEffect(type: action.type)
                        .delay(duration: 0.2, queue: queue),
                    cancelation: action.type.rawValue
                )

            default:
                break
            }
        }
    }
    
    class EnvironmentMiddleware: BaseReducibleMiddleware<AppState> {
        static func buildLiveEnvironment(for store: some UDFCore.Store<AppState>) -> Environment {
            store.dispatch(
                Actions.UpdateFormField(keyPath: \TestForm.type, value: .liveEnvironment)
            )
            return Environment()
        }
        
        static func buildTestEnvironment(for store: some UDFCore.Store<AppState>) -> Environment {
            store.dispatch(
                Actions.UpdateFormField(keyPath: \TestForm.type, value: .testEnvironment)
            )
            return Environment()
        }
        
        var environment: Environment!
        
        struct Environment {}
        
        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.TestMiddleware where action.type == .testEnvironment:
                execute(
                    TestMiddlewareEffect(type: action.type)
                        .delay(duration: 0.2, queue: queue),
                    cancelation: action.type.rawValue
                )

            default:
                break
            }
        }
    }
}

private extension MiddlewareSubscriptionTests {
    private func setLiveEnvironment() {
        let original = class_getClassMethod(ProcessInfo.self, #selector(getter: ProcessInfo.processInfo))!
        let swizzled = class_getClassMethod(ProcessInfo.self, #selector(ProcessInfo.isInTestEnvironment))!
        method_exchangeImplementations(original, swizzled)
    }
}

fileprivate extension ProcessInfo {
    @objc class func isInTestEnvironment() -> Bool { false }
}
