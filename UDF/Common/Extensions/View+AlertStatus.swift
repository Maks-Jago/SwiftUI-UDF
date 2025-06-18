//===--- AlertModifier.swift -------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

public extension View {
    /// Attaches an alert to the view using the specified `AlertBuilder.AlertStatus`.
    ///
    /// **Deprecated**: This method now internally delegates to the new Dialog system.
    /// Please migrate to using `DialogStatus` with `.dialog(status:)` for new code.
    /// This method will be removed in version 1.5.1.
    ///
    /// This method modifies the view to present an alert based on the given `Binding<AlertBuilder.AlertStatus>`.
    /// The alert automatically updates its presentation state and content based on changes to the binding.
    ///
    /// - Parameter status: A binding to an `AlertBuilder.AlertStatus` that controls the presentation and content of the alert.
    /// - Returns: A modified view that displays an alert when the specified `AlertStatus` is updated.
    @available(*, deprecated, message: "Will be removed in future versions. Use .dialog(status:) instead.")
    func alert(status: Binding<AlertBuilder.AlertStatus>) -> some View {
        self.dialog(status: status)
    }
}
