import XCTest
@testable import UDF
import Combine
import UDFXCTest

final class MiddlewareCancelationTests: XCTestCase {

    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, cancel, message, didCancel

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidCancelEffect where action.cancelation == ObservableMiddlewareToCancel.Cancelation.message:
                //Actions.DidCancelEffect where ObservableMiddlewareToCancel.Cancelation.allCases.contains(action.cancelation):
                self = .didCancel

            case let action as Actions.DidCancelEffect where action.cancelation == ReducibleMiddlewareToCancel.Cancelation.reducibleMessage:
                //Actions.DidCancelEffect where ObservableMiddlewareToCancel.Cancelation.allCases.contains(action.cancelation):
                self = .didCancel

            case let action as Actions.DidCancelEffect where action.cancelation == ObservableRunMiddlewareToCancel.Cancelation.runMessage:
                //Actions.DidCancelEffect where ObservableMiddlewareToCancel.Cancelation.allCases.contains(action.cancelation):
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

    func testObservableMiddlewareCancelation() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.subscribe(ObservableMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow

        XCTAssertEqual(middlewareFlow, .loading)
        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .didCancel)
    }

    func testObservableRunMiddlewareToCancel() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.subscribe(ObservableRunMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        await fulfill(description: "Wait for dispatch action", sleep: 2)
        var middlewareFlow = await store.state.middlewareFlow

        XCTAssertEqual(middlewareFlow, .loading)
        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        let messagesCount = await store.state.runForm.messagesCount

        XCTAssertTrue(messagesCount >= 2)
        XCTAssertEqual(middlewareFlow, .didCancel)
    }

    func testReducibleMiddlewareToCancel() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.subscribe(ReducibleMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .loading)

        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        let messagesCount = await store.state.runForm.messagesCount

        XCTAssertEqual(messagesCount, 0)
        XCTAssertEqual(middlewareFlow, .didCancel)
    }
}

fileprivate extension Actions {

    struct Loading: Action {}
    struct CancelLoading: Action {}
}

// MARK: - Middlewares
private extension MiddlewareCancelationTests {

    final class ObservableMiddlewareToCancel: BaseObservableMiddleware<AppState> {
        struct Environment {

        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        enum Cancelation: CaseIterable {
            case message
        }

        func scope(for state: MiddlewareCancelationTests.AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: MiddlewareCancelationTests.AppState) {
            switch state.middlewareFlow {
            case .loading:
                execute(
                    Effect(action: Actions.Message(id: "message_id")).delay(duration: 2, queue: queue),
                    cancelation: Cancelation.message
                )

            case .cancel:
                cancel(by: Cancelation.message)

            default:
                break
            }
        }
    }

    final class ObservableRunMiddlewareToCancel: BaseObservableMiddleware<AppState> {
        struct Environment {

        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }


        enum Cancelation: CaseIterable {
            case runMessage
        }

        func scope(for state: MiddlewareCancelationTests.AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: MiddlewareCancelationTests.AppState) {
            switch state.middlewareFlow {
            case .loading:
                run(RunEffect(), cancelation: Cancelation.runMessage)

            case .cancel:
                cancel(by: Cancelation.runMessage)

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

    final class ReducibleMiddlewareToCancel: BaseReducibleMiddleware<AppState> {
        struct Environment {

        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        enum Cancelation: CaseIterable {
            case reducibleMessage
        }

        func reduce(_ action: some Action, for state: MiddlewareCancelationTests.AppState) {
            switch action {
            case is Actions.Loading:
                execute(
                    Effect(action: Actions.Message(id: "message_id")).delay(duration: 1, queue: queue),
                    cancelation: Cancelation.reducibleMessage
                )

            case is Actions.CancelLoading:
                cancel(by: Cancelation.reducibleMessage)

            default:
                break
            }
        }
    }
}
