@testable import UDF
import Testing
import Foundation
import Combine
import UDFSwiftTesting

@Suite struct StateEffectableTests {
    let store: TestStore<AppState>

    init() async {
        let appState = AppState(
            userForm: UserForm(currentUser: CurrentUser(id: 1, fullName: "name", token: "1234567890"))
        )
        store = await TestStore(initial: appState)
    }

    @Test("Middleware uses StateEffectable without an environment")
    func observeMiddlewareWithStateEffectable() async throws {
        await store.subscribe(CounterMiddleware.self)

        #expect(await store.state.counterFlow == .none, "CounterFlow should start in the .none state")
        #expect(await store.state.counterForm.counter == nil, "CounterForm should be nil in the initial state")

        await store.dispatch(Actions.IncrementCounter())
        var success = await waitForCondition {
            await store.state.counterFlow == .increment
        }
        #expect(success, "CounterFlow should transition to the .increment state")

        success = await waitForCondition { [store] in
            guard let counter = await store.state.counterForm.counter else {
                return false
            }

            return counter.value == 1
        }
        #expect(success, "CounterForm should increment the value by one")

        success = await waitForCondition { [store] in
            await store.state.counterFlow == .none
        }
        #expect(success, "CounterFlow should return to the .none state after incrementing the value")
    }

    @Test("Middleware uses StateEffectable with an environment")
    func observeMiddlewareWithStateEffectableAndEnvironment() async throws {
        let environment = LoadLastMessage()
        await store.subscribe(MessageMiddleware.self, environment: environment)
        #expect(await store.state.messageFlow == .none, "MessageFlow should start in the .none state")

        await store.dispatch(Actions.LoadPage(id: MessageFlow.id))
        var success = await waitForCondition {
            await store.state.messageFlow == .loading
        }
        #expect(success, "MessageFlow should transition to the .loading state")

        success = await waitForCondition { [store] in
            await store.state.messageForm.message == StateEffectableTests.fullMessage
        }
        await store.wait()
        #expect(success, "MessageForm should contain a non-nil message")

        #expect(await store.state.messageFlow == .none, "MessageFlow should return to the .none state after receiving a new message")
    }
    
    @Test("Middleware cancels StateEffectable when the token is missing")
    func observeMiddlewareWithMissingStateEffectableArguments() async throws {
        let environment = LoadLastMessage()
        await store.subscribe(MessageMiddleware.self, environment: environment)
        
        await store.dispatch(Actions.UpdateFormField<UserForm>(keyPath: \UserForm.currentUser, value: nil))
        await store.wait()
        #expect(await store.state.userForm.currentUser == nil, "UserForm.currentUser should be nil")
        #expect(await store.state.messageFlow == .none, "MessageFlow should start in the .none state")

        await store.dispatch(Actions.LoadPage(id: MessageFlow.id))
        let success = await waitForCondition {
            await store.state.messageFlow == .none
        }
        #expect(success, "MessageFlow should return to the .none state when the token is missing")
    }

    struct AppState: AppReducer {
        var userForm = UserForm()

        var counterForm = CounterForm()
        var counterFlow = CounterFlow()

        var messageForm = MessageForm()
        var messageFlow = MessageFlow()
    }

    struct UserForm: Form {
        var currentUser: CurrentUser?

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItem<CurrentUser>:
                self.currentUser = action.item

            default:
                break
            }
        }
    }

    struct CounterForm: Form {
        var counter: Counter?

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItem<Counter>:
                counter = action.item

            default:
                break
            }
        }
    }

    struct MessageForm: Form {
        var message: String?

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItem<Message>:
                message = action.item.content

            default:
                break
            }
        }
    }

    enum CounterFlow: IdentifiableFlow {
        case none
        case increment

        init() {
            self = .none
        }

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.IncrementCounter:
                self = .increment

            case is Actions.DidLoadItem<Counter>:
                self = .none

            case let action as Actions.DidCancelEffect where action.cancellation == CounterMiddleware.Cancellation.increment:
                self = .none

            default:
                break
            }
        }
    }

    enum MessageFlow: IdentifiableFlow {
        case none
        case loading

        init() {
            self = .none
        }

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.LoadPage:
                self = .loading

            case is Actions.DidLoadItem<Message>:
                self = .none

            case let action as Actions.DidCancelEffect where action.cancellation == MessageMiddleware.Cancellation.message:
                self = .none

            default:
                break
            }
        }
    }
}

extension StateEffectableTests {
    struct CurrentUser: Equatable {
        let id: Int
        let fullName: String
        let token: String?
    }

    struct Message: Equatable {
        let content: String
    }

    struct Counter: Equatable {
        let value: Int
    }
}

private extension StateEffectableTests {
    final class CounterMiddleware: Middleware<AppState>, @unchecked Sendable {
        typealias Environment = Void

        enum Cancellation: CaseIterable {
            case increment
        }

        var environment: Environment!

        func scope(for state: AppState) -> Scope {
            state.counterFlow
        }

        func observe(state: AppState) {
            switch state.counterFlow {
            case .increment:
                execute(
                    effect: IncrementCounterStateEffectable(),
                    flowId: CounterFlow.id,
                    cancellation: Cancellation.increment
                )

            default:
                break
            }
        }

        struct IncrementCounterStateEffectable: StateEffectable, Sendable {
            func publisher(flowId: AnyHashable, state: AppState) -> AnyPublisher<any Action, Never> {
                let value = state.counterForm.counter?.value ?? .zero
                let counter = Counter(value: value + 1)

                return Just(Actions.DidLoadItem(item: counter, id: flowId) as any Action)
                    .delay(for: .milliseconds(500), scheduler: DispatchQueue.global())
                    .eraseToAnyPublisher()
            }
        }
    }

    final class MessageMiddleware: Middleware<AppState>, @unchecked Sendable {
        typealias Environment = LoadMessageEnvironment
        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            LoadLastMessage()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            LoadLastMessage()
        }

        enum Cancellation: CaseIterable {
            case message
        }

        func scope(for state: AppState) -> Scope {
            state.messageFlow
        }

        func observe(state: AppState) {
            switch state.messageFlow {
            case .loading:
                execute(
                    effect: MessageStateEffectable(environment: environment),
                    flowId: MessageFlow.id,
                    cancellation: Cancellation.message
                )
                
            default:
                break
            }
        }

        struct MessageStateEffectable: StateEffectable, Sendable {
            var environment: LoadMessageEnvironment

            func publisher(flowId: AnyHashable, state: AppState) throws -> AnyPublisher<any Action, Never> {
                guard let token = state.userForm.currentUser?.token else {
                    throw CancellationError()
                }

                return environment.loadMessage(token: token)
                    .map { message in
                        Actions.DidLoadItem(item: Message(content: message), id: flowId)
                    }
                    .eraseToAnyPublisher()
            }
        }
    }
}

extension StateEffectableTests {
    protocol LoadMessageEnvironment: Sendable {
        func loadMessage(token: String) -> AnyPublisher<String, Never>
    }

    private static var fullMessage: String {
        "Thanks for your message. We'll review it and get back to you shortly."
    }

    struct LoadLastMessage: LoadMessageEnvironment {
        func loadMessage(token: String) -> AnyPublisher<String, Never> {
            return Just(StateEffectableTests.fullMessage)
                .delay(for: .seconds(1), scheduler: DispatchQueue.global())
                .eraseToAnyPublisher()
        }
    }
}
