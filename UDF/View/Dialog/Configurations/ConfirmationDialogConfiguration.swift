//===--- ConfirmationDialogConfiguration.swift ---------------------------------===//
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

/// Configuration for confirmation dialog presentation.
///
/// Handles iOS-specific requirements for action sheet presentation,
/// particularly the title visibility behavior that differs between devices.
public struct ConfirmationDialogConfiguration: Hashable, Sendable {
    /// Controls title visibility in the dialog.
    ///
    /// iOS hides titles on iPhone for cleaner appearance but shows them
    /// on iPad where there's more space in the popover presentation.
    public var titleVisibility: Visibility
    
    /// Creates a confirmation dialog configuration.
    ///
    /// - Parameter titleVisibility: How to handle the dialog title. Defaults to .automatic.
    public init(titleVisibility: Visibility = .automatic) {
        self.titleVisibility = titleVisibility
    }
    
    /// Default configuration with automatic title handling.
    public static let `default` = ConfirmationDialogConfiguration()
}
