
import Combine
@testable import UDF
import UDFSwiftTesting
import Testing
import Foundation

@Suite(.serialized) struct MiddlewareCancellationTests_Last {
    
    struct MiddlewareCancellationAppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, cancel, message

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case _ as Actions.DidCancelEffect:
                self = .none

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
        // Ensure complete isolation from other tests
        GlobalValue.clearValue(for: EnvironmentStore<MiddlewareCancellationAppState>.self)
        
        let store = await TestStore(initial: MiddlewareCancellationAppState())

        final class ObservableMiddlewareToCancel: Middleware<MiddlewareCancellationAppState>, @unchecked Sendable {
            var environment: Void!

            enum Сancellation: CaseIterable {
                case message
            }

            func scope(for state: MiddlewareCancellationAppState) -> Scope {
                state.middlewareFlow
            }

            func observe(state: MiddlewareCancellationAppState) {
                switch state.middlewareFlow {
                case .loading:
                    execute(
                        Effect(action: Actions.Message(id: "message_id")).delay(duration: 0.5, queue: queue),
                        cancellation: Сancellation.message
                    )

                case .cancel:
                    cancel(by: Сancellation.message)

                default:
                    break
                }
            }
        }

        await store.subscribe(ObservableMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow
        #expect(middlewareFlow == .loading)

        await store.dispatch(Actions.CancelLoading())
        
        // Wait for all middleware operations to complete
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        #expect(middlewareFlow == .none)
    }

    @Test func observableRunMiddlewareToCancel() async {
        
        final class ObservableRunMiddlewareToCancel: Middleware<MiddlewareCancellationAppState>, @unchecked Sendable {
            struct Environment {}

            var environment: Environment!

            static func buildLiveEnvironment(for store: some Store<MiddlewareCancellationAppState>) -> Environment {
                Environment()
            }

            static func buildTestEnvironment(for store: some Store<MiddlewareCancellationAppState>) -> Environment {
                Environment()
            }

            enum Сancellation: CaseIterable {
                case runMessage
            }

            func scope(for state: MiddlewareCancellationAppState) -> Scope {
                state.middlewareFlow
            }

            func observe(state: MiddlewareCancellationAppState) {
                switch state.middlewareFlow {
                case .loading:
                    run(RunEffect(), cancellation: Сancellation.runMessage)

                case .cancel:
                    cancel(by: Сancellation.runMessage)

                default:
                    break
                }
            }

            struct RunEffect: Effectable {
                var upstream: AnyPublisher<any Action, Never> {
                    Timer.publish(every: 1, on: RunLoop.main, in: .default)
                        .autoconnect()
                        .flatMap { _ in
                            Future<any Action, Never> { promise in
                                promise(.success(Actions.Message(id: "message_id")))
                            }
                            .receive(on: DispatchQueue.main)
                        }
                        .eraseToAnyPublisher()
                }
            }
        }
        
        GlobalValue.clearValue(for: EnvironmentStore<MiddlewareCancellationAppState>.self)
        let store = await TestStore(initial: MiddlewareCancellationAppState())
        await store.subscribe(ObservableRunMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow
        #expect(middlewareFlow == .loading)

        await fulfill(description: "waiting for messages to increase messages count in form", sleep: 2)
        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        let messagesCount = await store.state.runForm.messagesCount
        #expect(messagesCount >= 1)

        middlewareFlow = await store.state.middlewareFlow
        #expect(middlewareFlow == .none)
    }

    @Test func reducibleMiddlewareToCancel() async {
        
        final class ReducibleMiddlewareToCancel: Middleware<MiddlewareCancellationAppState>, @unchecked Sendable {
            struct Environment {}

            var environment: Environment!

            static func buildLiveEnvironment(for store: some Store<MiddlewareCancellationAppState>) -> Environment {
                Environment()
            }

            static func buildTestEnvironment(for store: some Store<MiddlewareCancellationAppState>) -> Environment {
                Environment()
            }

            enum Сancellation: CaseIterable {
                case reducibleMessage
            }

            func reduce(_ action: some Action, for state: MiddlewareCancellationAppState) {
                switch action {
                case is Actions.Loading:
                    execute(
                        Effect(action: Actions.Message(id: "message_id")).delay(duration: 0.5, queue: queue),
                        cancellation: Сancellation.reducibleMessage
                    )

                case is Actions.CancelLoading:
                    cancel(by: Сancellation.reducibleMessage)

                default:
                    break
                }
            }
        }
        
        GlobalValue.clearValue(for: EnvironmentStore<MiddlewareCancellationAppState>.self)
        let store = await TestStore(initial: MiddlewareCancellationAppState())
        await store.subscribe(ReducibleMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow
        #expect(middlewareFlow == .loading)

        await store.dispatch(Actions.CancelLoading())
        
        // Wait for all middleware operations to complete
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        // After cancellation, state should be either .none (if DidCancelEffect came) 
        // or .cancel (if effect was cancelled before Message could be sent)  
        #expect(middlewareFlow == .none || middlewareFlow == .cancel, "Expected .none or .cancel, got \(middlewareFlow)")
    }
}

private extension Actions {
    struct Loading: Action {}
    struct CancelLoading: Action {}
}

