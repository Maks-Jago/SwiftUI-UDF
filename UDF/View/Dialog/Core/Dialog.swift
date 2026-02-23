//===--- Dialog.swift ----------------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A protocol representing a type-safe dialog that can be registered with ``DialogRegistration``.
///
/// Concrete conforming types — ``Alert``, ``Toast``, and ``ConfirmationDialog`` —
/// each use a dedicated result builder to ensure only valid components are accepted
/// at compile time, producing clear error messages for unsupported usage.
///
/// Each conforming type exposes a ``customType`` property that returns the internal
/// ``DialogCustomType`` representation used by the dialog presentation system.
///
/// ## Conforming Types
/// | Type                   | Builder                              | Style                  |
/// |------------------------|--------------------------------------|------------------------|
/// | ``Alert``              | ``AlertComponentBuilder``            | `.alert`               |
/// | ``Toast``              | ``ToastComponentBuilder``            | `.toast(config)`       |
/// | ``ConfirmationDialog`` | ``ConfirmationDialogComponentBuilder``| `.confirmationDialog`  |
public protocol Dialog: Sendable {
    /// The type-erased dialog representation used by the presentation layer.
    var customType: DialogCustomType<AnyView, AnyView> { get }
}
