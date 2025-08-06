
import Combine
@testable import UDF
import Testing
import Foundation

@Suite(.serialized) struct ConcurrencyMiddlewareCancellationTests {
    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, cancel, messageConcurrencyTests, didCancel

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.DidCancelEffect:
                self = .didCancel

            case is Actions.Loading:
                self = .loading

            case is Actions.CancelLoading:
                self = .cancel

            case is Actions.Message:
                self = .messageConcurrencyTests

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
        // Clear any global state from other tests
        GlobalValue.clearValue(for: EnvironmentStore<AppState>.self)

        let store = await TestStore(initial: AppState())
        await store.subscribe(ObservableMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        // Give the middleware time to start the effect before checking state
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        var middlewareFlow = await store.state.middlewareFlow

        #expect(middlewareFlow == .loading)
        await store.dispatch(Actions.CancelLoading())

        // Give more time for cancellation to propagate
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        #expect(middlewareFlow == .didCancel)
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
                // Run indefinitely until cancelled
                while !Task.isCancelled {
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }

                // This should never be reached due to cancellation
                return Actions.Message(message: "Success message", id: flowId)
            }
        }
    }
}
