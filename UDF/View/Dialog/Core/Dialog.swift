//===--- Dialog.swift ----------------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A protocol representing a type-safe dialog that can be registered with ``DialogRegistry``.
///
/// Concrete conforming types — ``Alert``, ``Toast``, and ``ConfirmationDialog`` —
/// each use a dedicated result builder to ensure only valid components are accepted
/// at compile time, producing clear error messages for unsupported usage.
///
/// `Dialog` extends ``DialogTypeProtocol`` directly, meaning each conforming type
/// is a first-class dialog type that the presentation layer can consume without
/// any intermediate conversion through `DialogCustomType` or `DialogContent`.
///
/// Conforming types must provide a ``payload`` (the parsed builder output) and a
/// ``dialogStyle`` (`.alert`, `.toast(config)`, or `.confirmationDialog(config)`).
/// All other `DialogTypeProtocol` requirements are fulfilled by default implementations.
///
/// ## Conforming Types
/// | Type                   | Builder                              | Style                  |
/// |------------------------|--------------------------------------|------------------------|
/// | ``Alert``              | ``AlertComponentBuilder``            | `.alert`               |
/// | ``Toast``              | ``ToastComponentBuilder``            | `.toast(config)`       |
/// | ``ConfirmationDialog`` | ``ConfirmationDialogComponentBuilder``| `.confirmationDialog`  |
public protocol Dialog: DialogTypeProtocol {
    /// The parsed dialog components produced by the result builder.
    var payload: DialogPayload { get }

    /// The presentation style for this dialog.
    var dialogStyle: DialogStyle { get }
}

// MARK: - Default DialogTypeProtocol conformance
extension Dialog {
    public var style: DialogStyle { dialogStyle }
    public var title: String { payload.title() }
    public var message: String? { payload.message() }
    public var actions: [any DialogAction] { payload.actions }
    public var category: DialogCategory { .custom }

    public func getIconView(theme: ToastTheme) -> AnyView? {
        payload.icon?()
    }

    public func getCustomContentView() -> AnyView? {
        payload.customContentView?()
    }
}

// MARK: - Equatable & Hashable
extension Dialog {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.actions.count == rhs.actions.count &&
        lhs.style == rhs.style
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(actions.count)
        hasher.combine(style)
    }

    public func isEqual(_ rhs: IsEquatable) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return self == rhs
    }
}
