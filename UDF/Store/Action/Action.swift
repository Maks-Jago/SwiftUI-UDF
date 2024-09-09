//
//  Action.swift
//  UDF
//
//  Created by Max Kuznetsov on 04.06.2020.
//  Copyright © 2020 Max Kuznetsov. All rights reserved.
//

import Foundation
import SwiftUI

public protocol Action: Equatable {}

public extension Action {
    func with(animation: Animation?) -> some Action {
        if let group = self as? ActionGroup {
            return ActionGroup(internalActions: group._actions.map({ oldAction in
                var mutableCopy = oldAction
                mutableCopy.animation = animation
                return mutableCopy
            }))

        } else {
            return ActionGroup(internalActions: [InternalAction(self, animation: animation)])
        }
    }
}

public extension Action {
    func silent() -> some Action {
        if let group = self as? ActionGroup {
            return ActionGroup(internalActions: group._actions.map({ oldAction in
                var mutableCopy = oldAction
                mutableCopy.silent = true
                return mutableCopy
            }))

        } else {
            return ActionGroup(internalActions: [InternalAction(self, silent: true)])
        }
    }
}

public extension Action {
    func binded<BindedContainer: BindableContainer>(to containerType: BindedContainer.Type, by id: BindedContainer.ID) -> some Action {
        if let group = self as? ActionGroup {
            return ActionGroup(internalActions: group._actions.map({ oldAction in
                InternalAction(
                    oldAction.value.binded(to: containerType, by: id),
                    animation: oldAction.animation,
                    silent: oldAction.silent,
                    fileName: oldAction.fileName,
                    functionName: oldAction.functionName,
                    lineNumber: oldAction.lineNumber
                )
            }))

        } else {
            return ActionGroup(internalActions: [InternalAction(Actions.BindableAction(value: self, containerType: containerType, id: id))])
        }
    }
}

extension Actions {
    struct BindableAction<BindedContainer: BindableContainer>: Action {
        let value: any Action
        let containerType: BindedContainer.Type
        let id: BindedContainer.ID

        public static func == (lhs: BindableAction<BindedContainer>, rhs: BindableAction<BindedContainer>) -> Bool {
            areEqual(lhs.value, rhs.value)
        }
    }
}
