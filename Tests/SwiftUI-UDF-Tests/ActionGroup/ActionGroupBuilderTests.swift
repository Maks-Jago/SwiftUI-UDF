//
//  ActionGroupBuilderTests.swift
//  SwiftUI-UDFTests
//
//  Created by Max Kuznetsov on 18.09.2022.
//

@testable import UDF
import Testing
import SwiftUI
import Foundation

@Suite struct ActionGroupBuilderTests {
    @Test func whenVoid_ActionGroupShouldBeEmpty() {
        let group = ActionGroup {
            ()
        }

        #expect(group.actions.isEmpty, "An ActionGroup shouldn't have action when there is some Void in the builder")
    }

    @Test func whenConditionFalse_ActionGroupShouldBeEmpty() {
        let condition = false

        let group = ActionGroup {
            if condition {
                Actions.Message(message: "m1", id: "m1")
            }
        }

        #expect(group.actions.isEmpty)
    }

    @Test func whenConditionTrue_ActionGroupShouldNotBeEmpty() {
        let condition = true

        let group = ActionGroup {
            if condition {
                Actions.Message(message: "m1", id: "m1")
            }
        }

        #expect(!group.actions.isEmpty)
    }

    @Test func whenConditionFalseWithPrefixAction_ActionGroupShouldHaveOneAction() {
        let condition = false

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")

            if condition {
                Actions.Message(message: "m2", id: "m2")
            }
        }

        #expect(group.actions.count == 1)
    }

    @Test func whenElseConditionFalseWithPrefixAction_ActionGroupShouldHaveTwoActions() {
        let condition = false

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")

            if condition {
                Actions.Message(message: "m2", id: "m2")
            } else {
                Actions.Message(message: "m3", id: "m3")
            }
        }

        #expect(group.actions.count == 2)
    }

    @Test func whenIfElseConditionFalseWithPrefixAction_ActionGroupShouldHaveTwoActions() {
        let condition = false

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")

            if condition {
                Actions.Message(message: "m2", id: "m2")
            } else if condition == false {
                Actions.Message(message: "m3", id: "m3")
            } else {
                Actions.Message(message: "m4", id: "m3")
            }
        }

        #expect(group.actions.count == 2)
    }

    @Test func `switch`() {
        let value = 4

        let group = ActionGroup {
            switch value {
            case 0:
                Actions.Message(message: "m0", id: "m0")

            case 1 ... 4:
                Actions.Message(message: "m4", id: "m4")

            case 4...:
                Actions.Message(message: "m5", id: "m5")

            default:
                ()
            }
        }

        #expect(group.actions.count == 1)
    }

    @Test func loop() {
        let group = ActionGroup {
            for i in 0 ... 3 {
                Actions.Message(message: "m\(i)", id: "m\(i)")
            }

            Actions.Message(message: "m5", id: "m5")
        }

        #expect(group.actions.count == 5)
    }

    @Test func optionalAction() {
        let optionalActionWithValue: (any Action)? = Actions.Message(message: "m1", id: "m1")
        let optionalActionNil: (any Action)? = nil

        let group = ActionGroup {
            optionalActionWithValue
            optionalActionNil
        }

        #expect(group.actions.count == 1)
    }

    @Test func actionGroupDeduplication() {
        struct TestAction: Action {}
        
        // Identical actions must be deduplicated
        let group1 = ActionGroup {
            TestAction()
            TestAction()
        }
        #expect(InternalAction(group1).unwrapActions().count == 1)
        
        // Bindable actions for different containers must NOT be deduplicated
        let group2 = ActionGroup {
            Actions._BindableAction(value: TestAction(), containerType: TestContainer.self, id: 1)
            Actions._BindableAction(value: TestAction(), containerType: TestContainer.self, id: 2)
        }
        #expect(InternalAction(group2).unwrapActions().count == 3)
        
        // Navigation actions to different screens must NOT be deduplicated
        let group3 = ActionGroup {
            Actions.Navigate(to: "home")
            Actions.Navigate(to: "settings")
        }
        #expect(InternalAction(group3).unwrapActions().count == 2)
    }

    @Test func nestedActionGroupFlatteningAndDeduplication() {
        struct TestAction: Action {}
        
        let nestedGroup = ActionGroup {
            ActionGroup {
                TestAction()
            }
            TestAction()
        }
        
        #expect(InternalAction(nestedGroup).unwrapActions().count == 1)
    }

    @Test func bindableActionsWithDifferentPayloads() {
        struct ActionWithPayload: Action {
            let value: String
        }
        struct OtherAction: Action {}
        
        let group = ActionGroup {
            Actions._BindableAction(value: ActionWithPayload(value: "A"), containerType: TestContainer.self, id: 1)
            Actions._BindableAction(value: ActionWithPayload(value: "B"), containerType: TestContainer.self, id: 1)
            Actions._BindableAction(value: OtherAction(), containerType: TestContainer.self, id: 1)
        }
        
        #expect(InternalAction(group).unwrapActions().count == 6)
    }

    @Test func actionsArrayExpression() {
        let analyticsActions: [any Action] = [
            Actions.Message(message: "a1", id: "a1"),
            Actions.Message(message: "a2", id: "a2"),
        ]

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")
            analyticsActions
        }

        #expect(group.actions.count == 3)
    }

    @Test func mixedIndividualActionsAndArrayOfActions() {
        let firstBatch: [any Action] = [
            Actions.Message(message: "b1", id: "b1"),
            Actions.Message(message: "b2", id: "b2"),
        ]
        let secondBatch: [any Action] = [
            Actions.Message(message: "b3", id: "b3"),
        ]

        let group = ActionGroup {
            firstBatch
            Actions.Message(message: "m1", id: "m1")
            secondBatch
        }

        #expect(group.actions.count == 4)
    }

    @Test func emptyActionsArrayExpression() {
        let emptyActions: [any Action] = []

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")
            emptyActions
        }

        #expect(group.actions.count == 1)
    }
}

// MARK: - Test Types
private struct TestState: AppReducer, Equatable {
    struct TestStateForm: UDF.Form, Equatable {
        mutating func reduce(_ action: some Action) {}
    }
    
    var form = TestStateForm()
    mutating func reduce(_ action: some Action) {}
}

private struct TestContainer: BindableContainer {
    typealias ContainerComponent = TestComponent
    typealias ContainerState = TestState
    
    var id: Int
    
    func scope(for state: TestState) -> Scope {
        state.form
    }
    
    func map(store: EnvironmentStore<TestState>) -> TestComponent.Props {
        .init()
    }
}

private struct TestComponent: Component {
    struct Props {}
    var props: Props
    var body: some View { EmptyView() }
}


