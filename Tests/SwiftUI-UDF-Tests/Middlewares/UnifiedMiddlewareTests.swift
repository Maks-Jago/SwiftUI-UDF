//===--- UnifiedMiddlewareTests.swift ----------------------------===//
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
import XCTest

private extension Actions {
    struct SendMessage: Action {
        var message: String
        var id: AnyHashable? = nil
    }
}

final class UnifiedMiddlewareTests: XCTestCase {
    struct AppState: AppReducer {
        var testForm = TestForm()
        var testFlow = TestFlow()
    }
    
    struct TestForm: Form {
        var title: String = ""
        var nested: NestedForm = .init()
    }
    
    struct NestedForm: Form {
        var number: Int = 0
    }
    
    enum TestFlow: IdentifiableFlow {
        case none
        case sending(message: String)
        
        init() { self = .none }
        
        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.SendMessage where action.id == Self.id:
                self = .sending(message: action.message)
                
            case let action as Actions.UpdateFormField<TestForm> where action.keyPath == \TestForm.title:
                self = .none
                
            default:
                break
            }
        }
    }
    
    class SendMessageMiddleware: BaseUnifiedMiddleware<AppState>, @unchecked Sendable {
        struct Environment: Sendable {
            var loadItems: @Sendable () -> [String]
        }
        
        var environment: Environment!
        
        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            .init(loadItems: { [] })
        }
        
        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            .init(loadItems: { [] })
        }
        
        func scope(for state: AppState) -> Scope {
            state.testFlow
        }
        
        var observeCount = 0
        
        func observe(state: AppState) {
            if case .sending = state.testFlow {
                observeCount += 1
            }
            
            switch state.testFlow {
            case let .sending(message):
                execute(
                    ServiceEffect(title: message, number: observeCount),
                    cancellation: "service"
                )
            default:
                break
            }
        }
        
        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case let action as Actions.SendMessage where action.id == nil:
                execute(
                    ServiceEffect(title: action.message, number: 0)
                        .delay(duration: 0.2, queue: queue),
                    cancellation: "service"
                )
            default:
                break
            }
        }
    }
    
    struct ServiceEffect: Effectable {
        var title: String
        var number: Int
        
        var upstream: AnyPublisher<any Action, Never> {
            Just(
                ActionGroup {
                    Actions.UpdateFormField(keyPath: \TestForm.title, value: title)
                    Actions.UpdateFormField(keyPath: \NestedForm.number, value: number)
                }
            )
            .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Tests
    func testUnifiedMiddleware_Reduce() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(SendMessageMiddleware.self)
        
        var formTitle = await store.state.testForm.title
        XCTAssertTrue(formTitle.isEmpty)
        
        let message = "Message 1"
        await store.dispatch(Actions.SendMessage(message: message))
        await store.wait()
        
        formTitle = await store.state.testForm.title
        XCTAssertEqual(formTitle, message)
        
        let numberValue = await store.state.testForm.nested.number
        XCTAssertEqual(numberValue, 0)
    }
    
    func testUnifiedMiddleware_Observe() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(SendMessageMiddleware.self)
        
        let message = "Flow message 1"
        await store.dispatch(Actions.SendMessage(message: message, id: TestFlow.id))
        await store.wait()
        
        let title = await store.state.testForm.title
        XCTAssertEqual(title, message)
        
        let numberValue = await store.state.testForm.nested.number
        XCTAssertEqual(numberValue, 1)
    }
    
    func testUnifiedMiddleware_DDosProtection() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(SendMessageMiddleware.self)
        await store.wait()
        
        var formTitle = await store.state.testForm.title
        XCTAssertTrue(formTitle.isEmpty)
        
        let message = "Flow message 1"
        await store.dispatch(Actions.SendMessage(message: message, id: TestFlow.id))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title1"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title2"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title3"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title4"))
        await store.wait()
        
        let numberValue = await store.state.testForm.nested.number
        XCTAssertEqual(numberValue, 1)
        
        formTitle = await store.state.testForm.title
        XCTAssertEqual(formTitle, "title4")
        
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title5"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "title6"))
        await store.wait()
        
        formTitle = await store.state.testForm.title
        XCTAssertEqual(formTitle, "title6")
    }
}
