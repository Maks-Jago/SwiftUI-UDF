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

/// A protocol representing a type-safe dialog (Alert, Toast, or ConfirmationDialog)
/// that can be converted to the internal `DialogCustomType`.
public protocol Dialog: Sendable {
    var customType: DialogCustomType<AnyView, AnyView> { get }
}
