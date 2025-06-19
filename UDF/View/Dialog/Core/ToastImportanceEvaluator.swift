//===--- ToastImportanceEvaluator.swift ----------------------------------===//
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

/// A utility for evaluating the importance of toasts in a dialog system.
/// This struct provides functionality to determine if any of the provided toasts
/// contain important messages that should be preserved in the queue.
public struct ToastImportanceEvaluator {
    /// Evaluates whether the provided toasts contain any important messages.
    /// Important messages are defined as those with a priority that should be preserved in the queue,
    /// or those categorized as error or warning.
    public static func hasImportantMessages(in toasts: [DialogType]) -> Bool {
        return toasts.contains { toast in
            if let priority = toast.toastConfiguration?.priority {
                return priority.shouldPreserveInQueue
            }
            
            return toast.category == .error || toast.category == .warning
        }
    }
    
    /// Filters the provided toasts to include only those that are considered important.
    public static func filterImportant(from toasts: [DialogType]) -> [DialogType] {
        return toasts.filter { toast in
            toast.toastConfiguration?.priority.shouldPreserveInQueue == true ||
            toast.category == .error || toast.category == .warning
        }
    }
    
    /// Categorizes the provided toasts into two groups: important and regular.
    public static func categorizeByImportance(_ toasts: [DialogType]) -> (important: [DialogType], regular: [DialogType]) {
        let important = filterImportant(from: toasts)
        let regular = toasts.filter { !important.contains($0) }
        return (important, regular)
    }
}
