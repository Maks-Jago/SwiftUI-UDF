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
