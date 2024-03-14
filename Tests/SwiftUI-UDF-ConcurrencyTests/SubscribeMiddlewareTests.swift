import XCTest
@testable import UDF
import Combine

fileprivate extension Actions {
    struct TestAction: Action {
        var id: SubscribeMiddlewareTests.MiddlewareId
    }
}

final class SubscribeMiddlewareTests: XCTestCase {
    @available(iOS 16.0.0, *)
    func testReducibleMiddleware() async throws {
        let store = try await XCTestStore(initial: AppState())
//        let envStore = try EnvironmentStore(initial: AppState(), loggers: [])

//        await envStore.subscribe(build: { store in
//            ObservableMiddleware.self
//            ReducibleMiddleware(store: store)
//        })

        await store.subscribe(build: { store in
            ObservableMiddleware.self
            ReducibleMiddleware(store: store)
            EnvironmentMiddleware(store: store, environment: EnvironmentMiddleware.buildTestEnvironment(for: store))
        })

        var middlewareId = await store.state.testForm.middlewareId
        XCTAssertNil(middlewareId)

        await store.dispatch(Actions.TestAction(id: .observable))
        await store.wait()
        middlewareId = await store.state.testForm.middlewareId
        XCTAssertEqual(middlewareId, .observable)
        
        await store.dispatch(Actions.TestAction(id: .reducible))
        await store.wait()
        middlewareId = await store.state.testForm.middlewareId
        XCTAssertEqual(middlewareId, .reducible)
        
        await store.dispatch(Actions.TestAction(id: .environment))
        await store.wait()
        middlewareId = await store.state.testForm.middlewareId
        XCTAssertEqual(middlewareId, .environment)
    }
}

// MARK: - AppState
extension SubscribeMiddlewareTests {
    
    enum MiddlewareId {
        case observable, reducible, environment
    }
    
    struct AppState: AppReducer {
        var testForm = TestForm()
        var testFlow = TestFlow()
    }
    
    enum TestFlow: IdentifiableFlow {
        case none, loading(MiddlewareId)
        
        init() { self = .none }
        
        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.TestAction where action.id == .observable:
                self = .loading(action.id)
                
            default:
                break
            }
        }
    }
    
    struct TestForm: Form {
        var middlewareId: MiddlewareId? = nil
    }
}

//MARK: - Middlewares
extension SubscribeMiddlewareTests {
    
    struct ServiceEffect: Effectable {
        var middlewareId: MiddlewareId

        var upstream: AnyPublisher<any Action, Never> {
            Just(
                Actions.UpdateFormField(keyPath: \TestForm.middlewareId, value: middlewareId)
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
            case .loading(let id):
                execute(
                    ServiceEffect(middlewareId: id)
                        .delay(duration: 0.2, queue: queue),
                    cancelation: id
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
            case let action as Actions.TestAction where action.id == .reducible:
                execute(
                    ServiceEffect(middlewareId: action.id)
                        .delay(duration: 0.2, queue: queue),
                    cancelation: action.id
                )

            default:
                break
            }
        }
    }
    
    class EnvironmentMiddleware: BaseReducibleMiddleware<AppState> {
        var environment: Void!
        
        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.TestAction where action.id == .environment:
                execute(
                    ServiceEffect(middlewareId: action.id)
                        .delay(duration: 0.2, queue: queue),
                    cancelation: action.id
                )

            default:
                break
            }
        }
    }
}

