
import Combine
@testable import UDF
import UDFSwiftTesting
import Testing
import Foundation

@Suite(.serialized) struct MiddlewareCancellationTests {
    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none
        case loading
        case loadingTask(id: Int)
        case executeEffect(id: Int)
        case runEffect(id: Int)
        case cancel
        case cancelAll
        case message

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidCancelEffect where action.cancellation == ObservableMiddlewareToCancel.Сancellation.message:
                self = .none

            case let action as Actions.DidCancelEffect
                where action.cancellation == ReducibleMiddlewareToCancel.Сancellation.reducibleMessage:
                self = .none

            case let action as Actions.DidCancelEffect where action.cancellation == ObservableRunMiddlewareToCancel.Сancellation.runMessage:
                self = .none

            case let action as Actions.DidCancelEffect
                where action.cancellation is ObservableMiddlewareToCancelAll.Сancellation:
                self = .none

            case is Actions.Loading:
                self = .loading

            case is Actions.CancelLoading:
                self = .cancel
                
            case is Actions.CancelAll:
                self = .cancelAll
                
            case let action as Actions.RunTaskByID:
                self = .loadingTask(id: action.id)
                
            case let action as Actions.ExecuteEffectByID:
                self = .executeEffect(id: action.id)

            case let action as Actions.RunEffectByID:
                self = .runEffect(id: action.id)

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
        await store.subscribe(ObservableMiddlewareToCancel.self, environment: ())
        await store.dispatch(Actions.Loading())
        var success = await store.state.middlewareFlow == .loading
        #expect(success)

        await store.dispatch(Actions.CancelLoading())

        success = await waitForCondition { await store.state.middlewareFlow == .none }
        
        #expect(success)
    }

    @Test func observableRunMiddlewareToCancel() async {
        let store = await TestStore(initial: AppState())
        await store.subscribe(ObservableRunMiddlewareToCancel.self, environment: ObservableRunMiddlewareToCancel.Environment())
        await store.dispatch(Actions.Loading())
        var success = await store.state.middlewareFlow == .loading
        #expect(success)

        success = await waitForCondition { await store.state.runForm.messagesCount > 0 }
        #expect(success)

        await store.dispatch(Actions.CancelLoading())

        success = await waitForCondition { await store.state.middlewareFlow == .none }
        #expect(success)
    }

    @Test func reducibleMiddlewareToCancel() async {
        let store = await TestStore(initial: AppState())
        await store.subscribe(ReducibleMiddlewareToCancel.self, environment: ReducibleMiddlewareToCancel.Environment())
        await store.dispatch(Actions.Loading())
        var success = await store.state.middlewareFlow == .loading
        #expect(success)

        await store.dispatch(Actions.CancelLoading())

        success = await waitForCondition { await store.state.middlewareFlow == .none }
        #expect(success)
    }
    
    @Test func testMiddlewareCancellationDataRace() async {
        let store = await TestStore(initial: AppState())
        await store.subscribe(ObservableMiddlewareToCancel.self, environment: ())
        
        await store.dispatch(Actions.Loading())
        var success = await store.state.middlewareFlow == .loading
        #expect(success)
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await store.dispatch(Actions.CancelLoading())
                }
            }
        }
        let acceptableFlowState: [MiddlewareFlow] = [.none, .cancel]
        success = acceptableFlowState.contains(await store.state.middlewareFlow)
        #expect(success)
        
        await store.wait()
    }

    @Test(arguments: CancellationAllAction.allCases)
    func testMiddlewareCancellationAll(action: CancellationAllAction) async throws {
        let store = await TestStore(initial: AppState())
        var observableMiddlewareToCancelAll: ObservableMiddlewareToCancelAll?
        await store.subscribe(build: { store in
            let middleware = ObservableMiddlewareToCancelAll(store: store, environment: ())
            observableMiddlewareToCancelAll = middleware
            return [MiddlewareWrapper(instance: middleware)]
        })

        let tasks = 10
        for id in 0..<tasks {
            await store.dispatch(action.makeActions(id: id))
        }

        try? await Task.sleep(for: .milliseconds(100))

        let middleware = try #require(observableMiddlewareToCancelAll, "The test should capture the subscribed ObservableMiddlewareToCancelAll instance")
        #expect(
            middleware.cancellations.count == tasks,
            "Expected \(tasks) tracked cancellations before CancelAll, got \(middleware.cancellations.count)"
        )

        await store.dispatch(Actions.CancelAll())
        await store.wait()

        #expect(
            middleware.cancellations.count == 0,
            "Expected all tracked cancellations to be removed after CancelAll, got \(middleware.cancellations.count)"
        )
        let messagesCount = await store.state.runForm.messagesCount
        #expect(messagesCount == 0, "Message count should remain unchanged after cancelling all \(action.description)")
    }
}

private extension Actions {
    struct Loading: Action {}
    struct RunTaskByID: Action {
        let id: Int
    }
    struct ExecuteEffectByID: Action {
        let id: Int
    }
    struct RunEffectByID: Action {
        let id: Int
    }
    struct CancelLoading: Action {}
    struct CancelAll: Action {}
}

// MARK: - Middlewares
private extension MiddlewareCancellationTests {
    final class ObservableMiddlewareToCancelAll: Middleware<AppState>, @unchecked Sendable {
        var environment: Void!
        
        enum Сancellation: Hashable {
            case message(Int)
        }

        func scope(for state: AppState) -> Scope {
            state.middlewareFlow
        }
        
        func observe(state: AppState) {
            switch state.middlewareFlow {
            case let .loadingTask(id):
                execute(
                    flowId: MiddlewareFlow.id,
                    cancellation: Сancellation.message(id)
                ) { flowID in
                    try? await Task.sleep(for: .seconds(1))
                    return Actions.Message(message: "message \(id)", id: flowID)
                }
                
            case let .executeEffect(id):
                execute(
                    Effect(action: Actions.Message(message: "message \(id)", id: MiddlewareFlow.id)).delay(duration: 1, queue: queue),
                    cancellation: Сancellation.message(id)
                )

            case let .runEffect(id):
                run(
                    Effect(action: Actions.Message(message: "message \(id)", id: MiddlewareFlow.id)).delay(duration: 1, queue: queue),
                    cancellation: Сancellation.message(id)
                )

            case .cancelAll:
                cancelAll()

            default:
                break
            }
        }
    }
    
    final class ObservableMiddlewareToCancel: Middleware<AppState>, @unchecked Sendable {
        var environment: Void!

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
                    Effect(action: Actions.Message(id: "message_id")).delay(duration: 1, queue: queue),
                    cancellation: Сancellation.message
                )

            case .cancel:
                cancel(by: Сancellation.message)

            default:
                break
            }
        }
    }

    final class ObservableRunMiddlewareToCancel: Middleware<AppState>, @unchecked Sendable {
        struct Environment {}

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        enum Сancellation: CaseIterable {
            case runMessage
        }

        func scope(for state: AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: AppState) {
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

    final class ReducibleMiddlewareToCancel: Middleware<AppState>, @unchecked Sendable {
        struct Environment {}

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        enum Сancellation: CaseIterable {
            case reducibleMessage
        }

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case is Actions.Loading:
                execute(
                    Effect(action: Actions.Message(id: "message_id")).delay(duration: 1, queue: queue),
                    cancellation: Сancellation.reducibleMessage
                )

            case is Actions.CancelLoading:
                cancel(by: Сancellation.reducibleMessage)

            default:
                break
            }
        }
    }
}

extension MiddlewareCancellationTests {
    enum CancellationAllAction: CaseIterable, Sendable, CustomStringConvertible {
        case task
        case executeEffect
        case runEffect
        case all

        var description: String {
            switch self {
            case .task:
                "tasks"
            case .executeEffect:
                "execute effects"
            case .runEffect:
                "run effects"
            case .all:
                "all executable task types"
            }
        }

        @ActionGroupBuilder
        func makeActions(id: Int) -> any Action {
            switch self {
            case .task:
                Actions.RunTaskByID(id: id)
            case .executeEffect:
                Actions.ExecuteEffectByID(id: id)
            case .runEffect:
                Actions.RunEffectByID(id: id)
            case .all:
                Actions.RunTaskByID(id: id)
                Actions.ExecuteEffectByID(id: id)
                Actions.RunEffectByID(id: id)
            }
        }
    }
}
