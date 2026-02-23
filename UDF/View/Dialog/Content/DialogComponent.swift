//===--- DialogComponent.swift ----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

public protocol DialogComponent: Sendable {}

public struct DialogTitle: DialogComponent {
    let value: String
    
    public init(_ value: String) {
        self.value = value
    }
}

public struct DialogMessage: DialogComponent {
    let value: String
    
    public init(_ value: String) {
        self.value = value
    }
}

public struct DialogIcon: DialogComponent {
    let value: @Sendable () -> AnyView

    public init<V>(@ViewBuilder _ value: @Sendable @escaping () -> V) where V : View, V : Sendable {
        self.value = { AnyView(value()) }
    }
}

public struct DialogComponentContent: DialogComponent {
    let value: @Sendable () -> AnyView

    public init<V>(@ViewBuilder _ value: @Sendable @escaping () -> V) where V : View, V : Sendable {
        self.value = { AnyView(value()) }
    }
}

public extension DialogContent where Icon == AnyView, CustomContent == AnyView {

    init(components: [DialogComponent]) {

        var title: @Sendable () -> String = { "" }
        var message: @Sendable () -> String? = { nil }

        var actions: [any DialogAction] = []

        var icon: (@Sendable () -> AnyView)? = nil
        var customContentView: (@Sendable () -> AnyView)? = nil

        for component in components {

            switch component {

            case let titleComponent as DialogTitle:
                title = { titleComponent.value }

            case let messageComponent as DialogMessage:
                message = { messageComponent.value }

            case let iconComponent as DialogIcon:
                icon = iconComponent.value

            case let contentComponent as DialogComponentContent:
                customContentView = contentComponent.value

            case let action as any DialogAction:
                actions.append(action)

            default:
                break
            }
        }

        self.title = title
        self.message = message
        self.actions = actions
        self.iconView = icon
        self.customContentView = customContentView
    }
}
