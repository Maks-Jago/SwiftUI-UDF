//
//  ActionGroupBuilderTests.swift
//  SwiftUI-UDFTests
//
//  Created by Max Kuznetsov on 18.09.2022.
//

@testable import UDF
import Testing

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
}
