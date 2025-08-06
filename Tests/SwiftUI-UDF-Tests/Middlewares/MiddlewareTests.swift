//===--- MiddlewareTests.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine
@testable import UDF
import Testing
import Foundation

private extension Actions {
    struct SendMessage: Action {
        var message: String
        var id: AnyHashable? = nil
    }

    struct TriggerFlow: Action {
        var flowName: String
        var id: AnyHashable? = nil
    }

    struct CompleteTask: Action {
        var taskId: String
        var id: AnyHashable? = nil
    }

    struct StartTask: Action {
        var taskId: String
        var id: AnyHashable? = nil
    }
}

@Suite(.serialized) struct MiddlewareTests {
    struct AppState: AppReducer {
        var testForm = TestForm()
        var testFlow = TestFlow()
        var taskFlow = TaskFlow()
    }

    struct TestForm: Form {
        var title: String = ""
        var description: String = ""
        var counter: Int = 0
    }

    enum TestFlow: IdentifiableFlow {
        case none
        case sending(message: String)
        case processing(data: String)

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.SendMessage where action.id == Self.id:
                self = .sending(message: action.message)

            case let action as Actions.TriggerFlow where action.id == Self.id:
                self = .processing(data: action.flowName)

            case let action as Actions.UpdateFormField<TestForm> where action.keyPath == \TestForm.title:
                self = .none

            default:
                break
            }
        }
    }

    enum TaskFlow: IdentifiableFlow {
        case idle
        case running(taskId: String)
        case completed(result: String)

        init() { self = .idle }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.StartTask where action.id == Self.id:
                self = .running(taskId: action.taskId)

            case let action as Actions.CompleteTask where action.id == Self.id:
                if case .running = self {
                    self = .completed(result: action.taskId)
                }

            default:
                break
            }
        }
    }

    // MARK: - Test Middlewares
    /// Tests only reduce functionality (like ReducibleMiddleware)
    class ReduceOnlyMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment: Sendable {
            var processMessage: @Sendable (String) -> String
        }

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            .init(processMessage: { "Processed: \($0)" })
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            .init(processMessage: { "Test: \($0)" })
        }

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.SendMessage where action.id == nil:
                let processed = environment.processMessage(action.message)
                execute(
                    UpdateTitleEffect(title: processed),
                    cancellation: "process_message"
                )

            default:
                break
            }
        }
    }

    /// Tests only observe functionality (like ObservableMiddleware)
    class ObserveOnlyMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment: Sendable {
            var reactToFlow: @Sendable (String) -> String
        }

        var environment: Environment!
        var observeCount = 0

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            .init(reactToFlow: { "Reacted to: \($0)" })
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            .init(reactToFlow: { "Test reaction: \($0)" })
        }

        func scope(for state: AppState) -> Scope {
            state.testFlow
        }

        func observe(state: AppState) {
            observeCount += 1

            switch state.testFlow {
            case let .sending(message):
                let reaction = environment.reactToFlow(message)
                execute(
                    UpdateDescriptionEffect(description: reaction),
                    cancellation: "react_to_flow"
                )

            case .processing(_):
                execute(
                    IncrementCounterEffect(increment: observeCount),
                    cancellation: "process_data"
                )

            default:
                break
            }
        }
    }

    /// Tests both reduce and observe functionality (full Middleware)
    class FullUnifiedMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment: Sendable {
            var handleMessage: @Sendable (String) -> String
            var processTask: @Sendable (String) -> String
        }

        var environment: Environment!
        var reduceCallCount = 0
        var observeCallCount = 0

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            .init(
                handleMessage: { "Handled: \($0)" },
                processTask: { "Processed task: \($0)" }
            )
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            .init(
                handleMessage: { "Test handled: \($0)" },
                processTask: { "Test task: \($0)" }
            )
        }

        @ScopeBuilder
        func scope(for state: AppState) -> Scope {
            state.testFlow
            state.taskFlow
        }

        func reduce(_ action: some Action, for state: AppState) {
            reduceCallCount += 1

            switch action {
            case let action as Actions.CompleteTask where action.id == nil:
                let result = environment.processTask(action.taskId)
                execute(
                    UpdateTitleEffect(title: result),
                    cancellation: "complete_task"
                )

            default:
                break
            }
        }

        func observe(state: AppState) {
            observeCallCount += 1

            switch state.taskFlow {
            case let .running(taskId):
                execute(
                    CompleteTaskEffect(taskId: taskId),
                    cancellation: "auto_complete"
                )

            case let .completed(result):
                execute(
                    UpdateDescriptionEffect(description: "Task completed: \(result)"),
                    cancellation: "update_completion"
                )

            default:
                break
            }
        }
    }

    /// Tests middleware with conditional scope
    class ConditionalScopeMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment: Sendable {}

        var environment: Environment!
        var shouldObserve = true

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            .init()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            .init()
        }

        func scope(for state: AppState) -> Scope {
            state.testFlow
        }

        func observe(state: AppState) {
            switch state.testFlow {
            case let .sending(message):
                execute(
                    UpdateTitleEffect(title: "Conditional: \(message)"),
                    cancellation: "conditional"
                )

            default:
                break
            }
        }
    }

    /// Tests middleware status changes
    class StatusChangeMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment: Sendable {}

        var environment: Environment!
        var isActive = true

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            .init()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            .init()
        }

        override func status(for state: AppState) -> MiddlewareStatus {
            isActive ? .active : .suspend
        }

        func scope(for state: AppState) -> Scope {
            state.testFlow
        }

        func observe(state: AppState) {
            switch state.testFlow {
            case let .sending(message):
                execute(
                    UpdateTitleEffect(title: "Status: \(message)"),
                    cancellation: "status"
                )

            default:
                break
            }
        }

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.SendMessage:
                execute(
                    UpdateDescriptionEffect(description: "Reduced: \(action.message)"),
                    cancellation: "reduce_status"
                )

            default:
                break
            }
        }
    }

    // MARK: - Effects
    struct UpdateTitleEffect: Effectable {
        var title: String

        var upstream: AnyPublisher<any Action, Never> {
            Just(Actions.UpdateFormField(keyPath: \TestForm.title, value: title))
                .eraseToAnyPublisher()
        }
    }

    struct UpdateDescriptionEffect: Effectable {
        var description: String

        var upstream: AnyPublisher<any Action, Never> {
            Just(Actions.UpdateFormField(keyPath: \TestForm.description, value: description))
                .eraseToAnyPublisher()
        }
    }

    struct IncrementCounterEffect: Effectable {
        var increment: Int

        var upstream: AnyPublisher<any Action, Never> {
            Just(Actions.UpdateFormField(keyPath: \TestForm.counter, value: increment))
            .eraseToAnyPublisher()
        }
    }

    struct CompleteTaskEffect: Effectable {
        var taskId: String

        var upstream: AnyPublisher<any Action, Never> {
            Just(Actions.CompleteTask(taskId: taskId, id: TaskFlow.id))
                .eraseToAnyPublisher()
        }
    }

    struct DelayedUpdateEffect: Effectable {
        var title: String
        var delay: TimeInterval

        var upstream: AnyPublisher<any Action, Never> {
            Just(Actions.UpdateFormField(keyPath: \TestForm.title, value: title))
                .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Tests
    /// Tests that Middleware works correctly when only implementing reduce functionality
    @Test func reduceOnlyMiddleware() async {
        // Given: A middleware that only implements reduce() method
        let store = await TestStore(initial: AppState())
        await store.subscribe(ReduceOnlyMiddleware.self)

        // When: An action is dispatched that should be handled by reduce()
        let message = "Test Message"
        await store.dispatch(Actions.SendMessage(message: message))
        await store.wait()

        // Then: The action should be processed and state updated accordingly
        let title = await store.state.testForm.title
        #expect(title == "Test: \(message)")
    }

    /// Tests that Middleware works correctly when only implementing observe functionality
    @Test func observeOnlyMiddleware() async {
        // Given: A middleware that only implements observe() method with a specific scope
        let store = await TestStore(initial: AppState())
        await store.subscribe(ObserveOnlyMiddleware.self)

        // When: An action is dispatched that changes the observed state flow
        let message = "Flow Message"
        await store.dispatch(Actions.SendMessage(message: message, id: TestFlow.id))
        await store.wait()

        // Then: The middleware should observe the state change and execute effects
        let description = await store.state.testForm.description
        #expect(description == "Test reaction: \(message)")
    }

    /// Tests that Middleware works correctly when implementing both reduce and observe functionality
    @Test func fullUnifiedMiddleware() async {
        // Given: A middleware that implements both reduce() and observe() methods
        let store = await TestStore(initial: AppState())
        await store.subscribe(FullUnifiedMiddleware.self)

        // When: An action is dispatched that should be handled by reduce()
        let taskId = "task123"
        await store.dispatch(Actions.CompleteTask(taskId: taskId))
        await store.wait()

        // Then: The reduce method should process the action
        let title = await store.state.testForm.title
        #expect(title == "Test task: \(taskId)")

        // When: An action triggers a state change that should be observed
        await store.dispatch(Actions.StartTask(taskId: "flow_task", id: TaskFlow.id))
        await store.wait()

        // Then: The observe method should react to the state change and auto-complete the task
        let description = await store.state.testForm.description
        #expect(description == "Task completed: flow_task")
    }

    /// Tests that Middleware works correctly with multiple scopes
    @Test func multipleScopes() async {
        // Given: A middleware that observes multiple state flows
        class MultiScopeMiddleware: Middleware<AppState>, @unchecked Sendable {
            struct Environment: Sendable {}
            var environment: Environment!

            static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment { .init() }
            static func buildTestEnvironment(for store: some Store<AppState>) -> Environment { .init() }

            @ScopeBuilder
            func scope(for state: AppState) -> Scope {
                state.testFlow
                state.taskFlow
            }

            func observe(state: AppState) {
                switch state.testFlow {
                case let .sending(message):
                    execute(
                        UpdateTitleEffect(title: "Multi: \(message)"),
                        cancellation: "multi_scope"
                    )
                default:
                    break
                }
            }
        }

        // When: The middleware is subscribed and an action changes one of the observed flows
        let store = await TestStore(initial: AppState())
        await store.subscribe(MultiScopeMiddleware.self)

        let message = "Multi Scope Message"
        await store.dispatch(Actions.SendMessage(message: message, id: TestFlow.id))
        await store.wait()

        // Then: The middleware should observe the change and execute effects
        let title = await store.state.testForm.title
        #expect(title == "Multi: \(message)")
    }

    /// Tests that Middleware correctly handles dynamic status changes
    @Test func middlewareStatusChanges() async {
        // Given: A middleware that changes status based on state conditions
        class StateBasedStatusMiddleware: Middleware<AppState>, @unchecked Sendable {
            struct Environment: Sendable {}
            var environment: Environment!

            static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment { .init() }
            static func buildTestEnvironment(for store: some Store<AppState>) -> Environment { .init() }

            override func status(for state: AppState) -> MiddlewareStatus {
                // Suspend when counter > 5
                return state.testForm.counter > 5 ? .suspend : .active
            }

            func scope(for state: AppState) -> Scope {
                state.testFlow
            }

            func observe(state: AppState) {
                switch state.testFlow {
                case let .sending(message):
                    execute(
                        UpdateTitleEffect(title: "Status: \(message)"),
                        cancellation: "status"
                    )
                default:
                    break
                }
            }

            func reduce(_ action: some Action, for state: AppState) {
                switch action {
                case let action as Actions.SendMessage:
                    execute(
                        UpdateDescriptionEffect(description: "Reduced: \(action.message)"),
                        cancellation: "reduce_status"
                    )
                default:
                    break
                }
            }
        }

        let store = await TestStore(initial: AppState())
        await store.subscribe(StateBasedStatusMiddleware.self)

        // When: Middleware is active (counter = 0) and actions are dispatched
        let message1 = "Active Message"
        await store.dispatch(Actions.SendMessage(message: message1, id: TestFlow.id))
        await store.wait()

        // Then: Both reduce and observe should work
        var title = await store.state.testForm.title
        var description = await store.state.testForm.description
        #expect(title == "Status: \(message1)")
        #expect(description == "Reduced: \(message1)")

        // When: State changes to suspend the middleware (counter > 5)
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.counter, value: 10))
        await store.wait()

        // And: Actions are dispatched while middleware is suspended
        let message2 = "Suspended Message"
        await store.dispatch(Actions.SendMessage(message: message2, id: TestFlow.id))
        await store.wait()

        // Then: Neither reduce nor observe should work
        title = await store.state.testForm.title
        description = await store.state.testForm.description
        #expect(title != "Status: \(message2)")
        #expect(description != "Reduced: \(message2)")

        // When: State changes to reactivate the middleware (counter <= 5)
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.counter, value: 1))
        await store.wait()

        // And: Actions are dispatched after reactivation
        let message3 = "Reactivated Message"
        await store.dispatch(Actions.SendMessage(message: message3, id: TestFlow.id))
        await store.wait()

        // Then: Both reduce and observe should work again
        title = await store.state.testForm.title
        description = await store.state.testForm.description
        #expect(title == "Status: \(message3)")
        #expect(description == "Reduced: \(message3)")
    }

    /// Tests that Middleware correctly observes changes across multiple scoped flows
    @Test func multipleScopesObservation() async {
        // Given: A middleware that observes multiple flows (testFlow and taskFlow)
        let store = await TestStore(initial: AppState())
        await store.subscribe(FullUnifiedMiddleware.self)

        // When: The first observed flow (testFlow) changes
        await store.dispatch(Actions.SendMessage(message: "test", id: TestFlow.id))
        await store.wait()

        // And: The second observed flow (taskFlow) changes
        await store.dispatch(Actions.StartTask(taskId: "task1", id: TaskFlow.id))
        await store.wait()

        // Then: The middleware should have observed both changes and executed effects
        let description = await store.state.testForm.description
        #expect(description == "Task completed: task1")
    }

    /// Tests that Middleware correctly handles effect cancellation when status changes
    @Test func middlewareCancellation() async {
        GlobalValue.clearValue(for: EnvironmentStore<AppState>.self)
        // Given: A middleware that can be suspended and cancels effects accordingly
        class CancellableMiddleware: Middleware<AppState>, @unchecked Sendable {
            struct Environment: Sendable {}
            var environment: Environment!

            static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment { .init() }
            static func buildTestEnvironment(for store: some Store<AppState>) -> Environment { .init() }

            override func status(for state: AppState) -> MiddlewareStatus {
                // Suspend when description contains "cancel"
                return state.testForm.description.contains("cancel") ? .suspend : .active
            }

            func reduce(_ action: some Action, for state: AppState) {
                switch action {
                case let action as Actions.CompleteTask:
                    // Add delay to simulate async work that can be cancelled
                    execute(
                        DelayedUpdateEffect(title: "Completed: \(action.taskId)", delay: 0.1),
                        cancellation: "delayed_task"
                    )
                default:
                    break
                }
            }
        }

        let store = await TestStore(initial: AppState())
        await store.subscribe(CancellableMiddleware.self)

        // When: A task starts that would execute a delayed effect
        await store.dispatch(Actions.CompleteTask(taskId: "task1"))

        // And: The middleware is immediately suspended (which should cancel ongoing effects)
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.description, value: "cancel all"))
        await store.wait()

        // Then: The delayed effect should have been cancelled before completion
        let title = await store.state.testForm.title
        #expect(title.isEmpty)
    }

    /// Tests that Middleware default implementations work correctly without custom logic
    @Test func defaultImplementations() async {
        // Given: A minimal middleware that uses only default implementations
        class MinimalMiddleware: Middleware<AppState>, @unchecked Sendable {
            struct Environment: Sendable {}
            var environment: Environment!

            static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
                .init()
            }

            static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
                .init()
            }

            // Uses default implementations:
            // - scope(for:) returns .none
            // - observe(state:) does nothing
            // - reduce(_:for:) does nothing
        }

        let store = await TestStore(initial: AppState())
        await store.subscribe(MinimalMiddleware.self)

        // When: Actions are dispatched that would normally be handled
        await store.dispatch(Actions.SendMessage(message: "test"))
        await store.wait()

        // Then: State should remain unchanged since no custom logic is implemented
        let state = await store.state
        #expect(state.testForm.title.isEmpty)
        #expect(state.testForm.description.isEmpty)
        #expect(state.testForm.counter == 0)
    }
}
