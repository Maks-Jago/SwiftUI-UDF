//===--- ToastPriority.swift ---------------------------------===//
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

public enum ToastPriority: Int, CaseIterable, Sendable {
    case low = 1        // Info messages, background updates
    case medium = 2     // Success notifications, warnings
    case high = 3       // User action results, important warnings
    case critical = 4   // Errors, security issues, payment failures
    
    var shouldPreserveInQueue: Bool { self.rawValue >= ToastPriority.high.rawValue }
}
