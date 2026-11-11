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
    
    @Test("Middleware injects its environment into Effectable")
    func middlewareInjectsEnvironmentIntoPureEffect() async throws {
        await store.subscribe(MessageMiddleware.self, environment: LoadLastMessage())

        await store.dispatch(Actions.LoadingMessageWithPureEffect())

        let success = await waitForCondition { [store] in
            await store.state.messageForm.message == StateEffectableTests.fullMessage
        }
        #expect(success, "PureEffect should load the message using the injected middleware environment")
        await store.wait()
    }

    @Test("Middleware injects its environment into a delayed Effectable")
    func middlewareInjectsEnvironmentIntoDelayedPureEffect() async throws {
        await store.subscribe(MessageMiddleware.self, environment: LoadLastMessage())

        await store.dispatch(Actions.LoadingMessageWithDelayedPureEffect())

        let success = await waitForCondition { [store] in
            let state = await store.state
            return state.messageForm.message == StateEffectableTests.fullMessage && state.messageFlow == .none
        }
        #expect(success, "Delayed PureEffect should load the message using the injected middleware environment and reset the flow")
        await store.wait()
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
    
    @Test("Execute StateEffectable using the fresh State")
    func observeMiddlewareWithUsageFreshAppState() async throws {
        var updatedUser = await store.state.userForm.currentUser
        let editedFullName = "Angelina Klochay"
        updatedUser?.fullName = editedFullName
        let user = try #require(updatedUser, "updateUser should be not nil")
        
        let environment = ProfileEnvironment(
            uploadAvatar: { _, _ in
                Just(URL(string: "https://google.com")!)
                    .setFailureType(to: Never.self)
                    .eraseToAnyPublisher()
            }, updateProfile: { _, _, _ in
                Just(user)
                    .setFailureType(to: Never.self)
                    .eraseToAnyPublisher()
            }
        )
        await store.subscribe(MyProfileMiddleware.self, environment: environment)
        
        await store.wait()
        #expect(await store.state.userForm.currentUser != nil, "UserForm.currentUser should not be nil")
        #expect(await store.state.userForm.currentUser?.fullName != editedFullName, "UserForm.currentUser.fullName should be not equal editedFullName")
        #expect(await store.state.userFlow == .none, "UserFlow should start in the .none state")
        
       
        await store.dispatch(Actions.UpdateProfile(fullName: editedFullName, avatarData: Data()))
        let success = await waitForCondition {
            let appState = await store.state
            
            return appState.userFlow == .none && appState.userForm.currentUser?.fullName == editedFullName
        }
        #expect(success, "StateEffectable should execute correctly using the withState Combine operator")
    }

    struct AppState: AppReducer {
        var userForm = UserForm()
        var userFlow = UserFlow()

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
    
    enum UserFlow: IdentifiableFlow {
        case none
        case update(fullName: String, avatarData: Data)
        
        init() { self = .none }
        
        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.UpdateProfile:
                self = .update(fullName: action.fullName, avatarData: action.avatarData)
            case is Actions.DidLoadItem<CurrentUser>:
                self = .none
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
        case loadingWithPureEffect
        case loadingWithDelayedPureEffect

        init() {
            self = .none
        }

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.LoadPage:
                self = .loading

            case is Actions.LoadingMessageWithPureEffect:
                self = .loadingWithPureEffect

            case is Actions.LoadingMessageWithDelayedPureEffect:
                self = .loadingWithDelayedPureEffect

            case is Actions.DidLoadItem<Message>:
                self = .none

            case let action as Actions.DidCancelEffect where action.cancellation == MessageMiddleware.Cancellation.message:
                self = .none

            case let action as Actions.DidCancelEffect where action.cancellation == MessageMiddleware.Cancellation.messageWithPureEffect:
                self = .none

            case let action as Actions.DidCancelEffect where action.cancellation == MessageMiddleware.Cancellation.messageWithDelayedPureEffect:
                self = .none

            default:
                break
            }
        }
    }
}
// MARK: - Actions
extension Actions {
    struct LoadingMessageWithPureEffect: Action {}
    struct LoadingMessageWithDelayedPureEffect: Action {}

    struct UpdateProfile: Action {
        let fullName: String
        let avatarData: Data
    }
}

extension StateEffectableTests {
    struct CurrentUser: Equatable {
        let id: Int
        var fullName: String
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
                    IncrementCounterStateEffectable(store: store),
                    cancellation: Cancellation.increment
                )

            default:
                break
            }
        }

        struct IncrementCounterStateEffectable: StateEffectInitializable, Sendable {
            var state: @Sendable () -> AppState
            
            var upstream: AnyPublisher<any Action, Never> {
                let value = self.state().counterForm.counter?.value ?? .zero
                let counter = Counter(value: value + 1)
                return Just(Actions.DidLoadItem(item: counter, id: CounterFlow.id) as any Action)
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
            case messageWithPureEffect
            case messageWithDelayedPureEffect
        }

        func scope(for state: AppState) -> Scope {
            state.messageFlow
        }

        func observe(state: AppState) {
            switch state.messageFlow {
            case .loading:
                execute(
                    MessageStateEffectable(store: store),
                    cancellation: Cancellation.message
                )

            case .loadingWithPureEffect:
                execute(
                    MessagePureEffect(token: state.userForm.currentUser?.token),
                    cancellation: Cancellation.messageWithPureEffect
                )

            case .loadingWithDelayedPureEffect:
                execute(
                    MessagePureEffect(token: state.userForm.currentUser?.token)
                        .delay(duration: 0.1, queue: queue),
                    cancellation: Cancellation.messageWithDelayedPureEffect
                )

            default:
                break
            }
        }

        struct MessagePureEffect: Effectable, EnvironmentEffect {
            var environment: LoadMessageEnvironment!
            let token: String?

            var upstream: AnyPublisher<Output, Failure> {
                guard let token else {
                    return Just(Actions.DidCancelEffect(by: Cancellation.messageWithPureEffect) as any Action)
                        .eraseToAnyPublisher()
                }
                return environment
                    .loadMessage(token: token)
                    .map { message in
                        Actions.DidLoadItem(item: Message(content: message), id: MessageFlow.id) as any Action
                    }
                    .eraseToAnyPublisher()
            }
        }

        struct MessageStateEffectable: StateEffectInitializable, EnvironmentEffect, Sendable {
            var environment: LoadMessageEnvironment!
            var state: @Sendable () -> AppState
            
            init(state: @escaping @Sendable () -> AppState) {
                self.state = state
            }
            
            var upstream: AnyPublisher<any Action, Never> {
                guard let token = state().userForm.currentUser?.token else {
                    return Just(Actions.DidCancelEffect(by: Cancellation.message) as any Action)
                        .eraseToAnyPublisher()
                }
                
                return environment.loadMessage(token: token)
                    .map { message in
                        Actions.DidLoadItem(item: Message(content: message), id: MessageFlow.id) as any Action
                    }
                    .eraseToAnyPublisher()
            }
        }
    }
    
    final class MyProfileMiddleware: Middleware<AppState>, @unchecked Sendable {
        var environment: ProfileEnvironment!
        
        static func buildLiveEnvironment(for store: some Store<AppState>) -> ProfileEnvironment {
            ProfileEnvironment(
                uploadAvatar: { _, _ in
                    Just(URL(string: "https://google.com")!)
                        .setFailureType(to: Never.self)
                        .eraseToAnyPublisher() },
                updateProfile: { _, _, _ in
                    Just(CurrentUser(id: 0, fullName: "", token: nil))
                        .setFailureType(to: Never.self)
                        .eraseToAnyPublisher()},
            )
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> ProfileEnvironment {
            ProfileEnvironment(
                uploadAvatar: { _, _ in
                    Just(URL(string: "https://google.com")!)
                        .setFailureType(to: Never.self)
                        .eraseToAnyPublisher() },
                updateProfile: { _, _, _ in
                    Just(CurrentUser(id: 0, fullName: "", token: nil))
                        .setFailureType(to: Never.self)
                        .eraseToAnyPublisher()},
            )
        }

        
        enum Cancellation: CaseIterable {
            case update
        }
        
        override func status(for state: StateEffectableTests.AppState) -> MiddlewareStatus {
            .active
        }
        
        func scope(for state: StateEffectableTests.AppState) -> any Scope {
            state.userForm
            state.userFlow
        }
        
        func observe(state: AppState) {
            switch state.userFlow {
            case let .update(fullName, avatarData):
                execute(
                    UpdateMyProfileEffectable(store: store, fullName: fullName, avatarData: avatarData),
                    cancellation: Cancellation.update
                )
            default:
                break
            }
        }
        
        struct UpdateMyProfileEffectable: StateEffectable, EnvironmentEffect {
            var environment: ProfileEnvironment!
            let state: @Sendable () -> State
            let fullName: String
            let avatarData: Data
            
            init(store: any Store<State>, fullName: String, avatarData: Data) {
                self.fullName = fullName
                self.avatarData = avatarData
                self.state = { [store] in store.currentState }
            }
            
            var upstream: AnyPublisher<any Action, Never> {
                guard
                    let token = state().userForm.currentUser?.token
                else {
                    return Just(Actions.DidCancelEffect(by: Cancellation.update) as any Action)
                        .eraseToAnyPublisher()
                }
                
                return environment.uploadAvatar(token, avatarData)
                    .map { url in
                        Actions.DidLoadItem(item: url, id: MessageFlow.id) as any Action
                    }
                    .eraseToAnyPublisher()
                    .compactMap { action -> URL? in
                        guard let urlAction = action as? Actions.DidLoadItem<URL> else {
                            return nil
                        }
                        return urlAction.item
                    }
                    .flatMap { url -> AnyPublisher<any Action, Never> in
                        guard
                            let token = state().userForm.currentUser?.token
                        else {
                            return Just(Actions.DidCancelEffect(by: Cancellation.update) as any Action)
                                .eraseToAnyPublisher()
                        }
                        return environment.updateProfile(token, fullName, url)
                            .map { user in
                                Actions.DidLoadItem(item: user) as any Action
                            }
                            .eraseToAnyPublisher()
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
    
    
    struct ProfileEnvironment: @unchecked Sendable {
        var uploadAvatar: (_ token: String, _ image: Data) -> AnyPublisher<URL, Never>
        var updateProfile: (_ token: String, _ fullName: String, _ avatarPath: URL) -> AnyPublisher<CurrentUser, Never>
    }
}
