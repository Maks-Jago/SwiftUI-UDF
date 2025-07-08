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
    public static func filterImportant(from toasts: [DialogTypeProtocol]) -> [DialogTypeProtocol] {
        toasts.filter { toast in
            guard case let .toast(configuration) = toast.style else {
                return false
            }
            return configuration.priority.shouldPreserveInQueue == true ||
            toast.category == .error || toast.category == .warning
        }
    }
    
    /// Categorizes the provided toasts into two groups: important and regular.
    public static func categorizeByImportance(_ toasts: [DialogTypeProtocol]) -> (important: [DialogTypeProtocol], regular: [DialogTypeProtocol]) {
        let important = filterImportant(from: toasts)
        let regular = toasts.filter { toast in
            !important.contains { importantToast in
                importantToast.isEqual(toast)
            }
        }

        return (important, regular)
    }
}
