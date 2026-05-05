
import Combine
@testable import UDF
import UDFSwiftTesting
import Testing
import Foundation

@Suite struct ConcurrencyMiddlewareCancellationTests {
    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, cancel, message, didCancel

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidCancelEffect where action.cancellation == ObservableMiddlewareToCancel.Сancellation.message:
                self = .didCancel

            case is Actions.Loading:
                self = .loading

            case is Actions.CancelLoading:
                self = .cancel

            case is Actions.Message:
                self = .message

            default:
                break
            }
        }
    }

    struct RunForm: Form {
        var messagesCount: Int = 0

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.Message:
                messagesCount += 1

            default:
                break
            }
        }
    }

    @Test func observableMiddlewareCancellation() async {
        let store = await TestStore(initial: AppState())
        await store.subscribe(ObservableMiddlewareToCancel.self, environment: ObservableMiddlewareToCancel.Environment(loadItems: { [] }))

        await store.dispatch(Actions.Loading())
        var success = await waitForCondition { await store.state.middlewareFlow == .loading }
        #expect(success)

        await store.dispatch(Actions.CancelLoading())
        success = await waitForCondition { await store.state.middlewareFlow == .didCancel }
        #expect(success)
    }
    
    @Test func testMiddlewareCancellationDataRace() async {
        let store = await TestStore(initial: AppState())
        await store.subscribe(ObservableMiddlewareToCancel.self, environment: ObservableMiddlewareToCancel.Environment(loadItems: { [] }))

        await store.dispatch(Actions.Loading())
        var success = await waitForCondition { await store.state.middlewareFlow == .loading }
        #expect(success)
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await store.dispatch(Actions.CancelLoading())
                }
            }
        }
        
        let acceptableFlowState: [MiddlewareFlow] = [.cancel, .didCancel]
        
        success = await waitForCondition { acceptableFlowState.contains(await store.state.middlewareFlow) }
        #expect(success)
        
        await store.wait()
    }
}

private extension Actions {
    struct Loading: Action {}
    struct CancelLoading: Action {}
}

// MARK: - Middlewares
private extension ConcurrencyMiddlewareCancellationTests {
    final class ObservableMiddlewareToCancel: Middleware<AppState>, @unchecked Sendable {
        struct Environment : Sendable{
            var loadItems: @Sendable () async -> [String]
        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(loadItems: { [] })
        }

        enum Сancellation: CaseIterable {
            case message
        }

        func scope(for state: AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: AppState) {
            switch state.middlewareFlow {
            case .loading:
                execute(
                    effect: SomeEffect(),
                    flowId: "message_id",
                    cancellation: Сancellation.message
                )

            case .cancel:
                cancel(by: Сancellation.message)

            default:
                break
            }
        }

        struct SomeEffect: ConcurrencyEffect {
            func task(flowId: AnyHashable) async throws -> any UDF.Action {
                await sleep(for: 1)

                try Task.checkCancellation()

                return Actions.Message(message: "Success message", id: flowId)
            }
        }
    }
}
