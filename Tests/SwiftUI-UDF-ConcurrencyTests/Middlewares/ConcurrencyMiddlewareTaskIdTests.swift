import Combine
import XCTest

@testable import UDF

final class ConcurrencyMiddlewareTaskIdTests: XCTestCase {
    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }
    
    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, didLoad
        
        init() { self = .none }
        
        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.Loading:
                self = .loading
                
            case let action as Actions.DidFinishLoading where action.id == Self.id:
                self = .didLoad
                
            default:
                break
            }
        }
    }
    
    struct RunForm: Form {
        var loadedCount: Int = 0
        
        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidFinishLoading where action.id == MiddlewareFlow.id:
                loadedCount += 1
                
            default:
                break
            }
        }
    }
    
    func testReducibleMiddlewareTaskId() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(TestReducibleMiddleware.self)
        
        var runForm = await store.state.runForm
        XCTAssertEqual(runForm.loadedCount, 0)
        
        await store.dispatch(Actions.Loading(id: MiddlewareFlow.id))
        await store.wait()
        
        runForm = await store.state.runForm
        XCTAssertEqual(runForm.loadedCount, 1)
    }
}

private extension Actions {
    struct Loading: Action {
        let id: AnyHashable
    }
    struct DidFinishLoading: Action {
        let id: AnyHashable
    }
}

// MARK: - Middlewares
private extension ConcurrencyMiddlewareTaskIdTests {
    final class TestReducibleMiddleware: BaseReducibleMiddleware<AppState> {
        struct Environment {
            var loadItems: () async -> [String]
        }
        
        var environment: Environment!
        
        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }
        
        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }
        
        enum Cancellation: CaseIterable {
            case loading
        }
        
        func reduce(_ action: some Action, for state: ConcurrencyMiddlewareTaskIdTests.AppState) {
            switch action {
            case let action as Actions.Loading:
                execute(
                    effect: SomeEffect(),
                    flowId: action.id,
                    cancellation: Cancellation.loading
                )
                
            default:
                break
            }
        }
        
        struct SomeEffect: ConcurrencyEffect {
            func task(flowId: AnyHashable) async throws -> any Action {
                return Actions.DidFinishLoading(id: flowId)
            }
        }
    }
}
