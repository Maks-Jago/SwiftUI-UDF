@testable import UDF
import Testing
import Foundation
import UDFSwiftTesting

@Suite struct ConcurrencyEffectTests {
    let store: TestStore<AppState>
    
    init() async {
        let appState = AppState(
            userForm: UserForm(currentUser: CurrentUser(id: 1, fullName: "name", token: "1234567890"))
        )
        store = await TestStore(initial: appState)
    }
    
    @Test("Middleware uses StateConcurrencyEffect without an environment")
    func observeMiddlewareWithStateConcurrencyEffect() async throws {
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
    
    @Test("Middleware uses StateConcurrencyEffect with an environment")
    func observeMiddlewareWithStateConcurrencyEffectAndEnvironment() async throws {
        let environments = MessageEnvironments(
            popular: LoadPopularMessage(),
            preview: LoadPreviewMessage()
        )
        await store.subscribe(MessageMiddleware.self, environment: environments)
        #expect(await store.state.messageFlow == .none, "MessageFlow should start in the .none state")

        await store.dispatch(Actions.LoadingPopularMessage())
        var success = await waitForCondition {
            await store.state.messageFlow == .loadingPopularMessage
        }
        #expect(success, "MessageFlow should transition to the .loadingPopularMessage state")
        
        success = await waitForCondition { [store] in
            await store.state.messageForm.message == ConcurrencyEffectTests.fullMessage
        }
        await store.wait()
        #expect(success, "MessageForm should contain a non-nil message")
        
        #expect(await store.state.messageFlow == .none, "MessageFlow should return to the .none state after receiving a new message")
        
        await store.dispatch(Actions.LoadingPreviewMessage())
        
        success = await waitForCondition { await store.state.messageFlow == .loadingPreviewMessage }
        #expect(success, "MessageFlow should transition to the .loadingPreviewMessage state")
        
        success = await waitForCondition { [store] in
            await store.state.messageForm.message == ConcurrencyEffectTests.previewMessage
        }
        #expect(success, "MessageForm should contain the newly received message")
        
        success = await waitForCondition { [store] in
            await store.state.messageFlow == .none
        }
        #expect(success, "MessageFlow should return to the .none state after receiving a new message")
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
                
            case let action as Actions.DidCancelEffect where action.cancellation == MessageMiddleware.Сancellation.message:
                self = .none
                
            default:
                break
            }
        }
    }
    
    enum MessageFlow: IdentifiableFlow {
        case none
        case loadingPopularMessage
        case loadingPreviewMessage

        init() {
            self = .none
        }

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.LoadingPopularMessage:
                self = .loadingPopularMessage
                
            case is Actions.LoadingPreviewMessage:
                self = .loadingPreviewMessage
                
            case is Actions.DidLoadItem<Message>:
                self = .none
                
            case let action as Actions.DidCancelEffect where action.cancellation == MessageMiddleware.Сancellation.message:
                self = .none
                
            default:
                break
            }
        }
    }
}

// MARK: - Actions
fileprivate extension Actions {
    struct LoadingPopularMessage: Action {}
    struct LoadingPreviewMessage: Action {}
    struct CancelLoading: Action {}
    struct IncrementCounter: Action {}
}

// MARK: - Models
extension ConcurrencyEffectTests {
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

// MARK: - Middlewares
private extension ConcurrencyEffectTests {
    final class MessageMiddleware: Middleware<AppState>, @unchecked Sendable {
        typealias Environment = MessageEnvironments
        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            MessageEnvironments(
                popular: EmptyLoadMessage(),
                preview: EmptyLoadMessage()
            )
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            MessageEnvironments(
                popular: LoadPopularMessage(),
                preview: LoadPreviewMessage()
            )
        }

        enum Сancellation: CaseIterable {
            case message
        }

        func scope(for state: AppState) -> Scope {
            state.messageFlow
        }

        func observe(state: AppState) {
            switch state.messageFlow {
            case .loadingPopularMessage:
                execute(
                    effect: MessageStateConcurrencyEffect(environment: environment.popular),
                    flowId: MessageFlow.id,
                    cancellation: Сancellation.message
                )
                
            case .loadingPreviewMessage:
                execute(
                    effect: MessageStateConcurrencyEffect(environment: environment.preview),
                    flowId: MessageFlow.id,
                    cancellation: Сancellation.message
                )
            default:
                break
            }
        }

        struct MessageStateConcurrencyEffect: StateConcurrencyEffect {
            var environment: LoadMessageEnvironment
            
            func task(flowId: AnyHashable, state: AppState) async throws -> any Action {
                guard let token = state.userForm.currentUser?.token else {
                    throw CancellationError()
                }
                let message = try await environment.loadMessage(token: token)
                
                return Actions.DidLoadItem(item: Message(content: message), id: flowId)
            }
        }
    }
    
    final class CounterMiddleware: Middleware<AppState>, @unchecked Sendable {
        typealias Environment = Void
        
        enum Сancellation: CaseIterable {
            case increment
        }
        
        var environment: Environment!
        
        func scope(for state: ConcurrencyEffectTests.AppState) -> any Scope {
            state.counterFlow
        }
        
        func observe(state: AppState) {
            switch state.counterFlow {
            case .increment:
                execute(
                    effect: IncrementCounterStateConcurrencyEffect(),
                    flowId: MessageFlow.id,
                    cancellation: Сancellation.increment
                )
            default:
                break
            }
        }
        
        struct IncrementCounterStateConcurrencyEffect: StateConcurrencyEffect {
            func task(flowId: AnyHashable, state: AppState) async throws -> any Action {
                try await Task.sleep(for: .milliseconds(500))
                let value = state.counterForm.counter?.value ?? .zero
                let counter = Counter(value: value + 1)
                
                return Actions.DidLoadItem(item: counter, id: flowId)
            }
        }
    }
}

// MARK: - Environment
extension ConcurrencyEffectTests {
    struct MessageEnvironments: Sendable {
        let popular: any LoadMessageEnvironment
        let preview: any LoadMessageEnvironment
    }

    protocol LoadMessageEnvironment: Sendable {
        func loadMessage(token: String) async throws -> String
    }
    
    private static var fullMessage: String {
        "Thanks for your message. We'll review it and get back to you shortly."
    }
    
    private static var previewMessage: String {
        String(fullMessage.prefix(20)).trimmingCharacters(in: .whitespacesAndNewlines).appending("...")
    }
    
    struct EmptyLoadMessage: LoadMessageEnvironment {
        func loadMessage(token: String) async throws -> String {
            return ""
        }
    }
    
    struct LoadPopularMessage: LoadMessageEnvironment {
        func loadMessage(token: String) async throws -> String {
            try await Task.sleep(for: .seconds(1))
            
            return ConcurrencyEffectTests.fullMessage
        }
    }
    
    struct LoadPreviewMessage: LoadMessageEnvironment {
        func loadMessage(token: String) async throws -> String {
            try await Task.sleep(for: .seconds(1))
            
            return ConcurrencyEffectTests.previewMessage
        }
    }
}
