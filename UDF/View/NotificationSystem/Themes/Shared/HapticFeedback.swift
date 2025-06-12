//===--- HapticFeedback.swift ---------------------------------===//
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
#if os(iOS)
import UIKit
#endif

/// Defines haptic feedback types for toast notifications.
///
/// `HapticFeedback` provides tactile feedback options that enhance the user
/// experience by providing physical sensations that correspond to different
/// notification types and importance levels. Haptic feedback helps users
/// understand the nature of notifications even when they can't see the screen.
///
/// ## Usage:
/// ```swift
/// // Semantic feedback for notification types
/// let config = ToastConfiguration(
///     theme: ToastTheme(
///         errorHaptic: .error,
///         successHaptic: .success,
///         warningHaptic: .warning
///     )
/// )
/// 
/// // Manual haptic triggering
/// HapticFeedback.success.trigger()
/// HapticFeedback.light.trigger()
/// ```
///
/// ## Platform Support:
/// - **iOS**: Full haptic feedback support using UIKit feedback generators
/// - **Other platforms**: Gracefully ignored (no-op implementation)
public enum HapticFeedback: CaseIterable, Hashable {
    
    // MARK: - Semantic Feedback Types
    
    /// Success haptic feedback for positive outcomes.
    /// 
    /// Provides a pleasant, confirmatory tactile sensation appropriate
    /// for successful operations, completions, and positive user actions.
    /// Uses the system's success notification pattern.
    /// 
    /// **Characteristics:**
    /// - Light, pleasant sensation
    /// - Brief duration
    /// - Positive emotional association
    /// - Maps to `UINotificationFeedbackGenerator.success` on iOS
    /// 
    /// **Use Cases:**
    /// - File saved successfully
    /// - Form submitted
    /// - Action completed
    /// - Goal achieved or milestone reached
    /// 
    /// ## Example:
    /// ```swift
    /// notification = .toastSuccess("File saved!", haptic: .success)
    /// ```
    case success
    
    /// Warning haptic feedback for cautionary situations.
    /// 
    /// Provides a noticeable but not alarming tactile sensation appropriate
    /// for warnings, cautions, and situations requiring user attention.
    /// Uses the system's warning notification pattern.
    /// 
    /// **Characteristics:**
    /// - Moderate intensity
    /// - Attention-getting without being jarring
    /// - Neutral to slightly negative association
    /// - Maps to `UINotificationFeedbackGenerator.warning` on iOS
    /// 
    /// **Use Cases:**
    /// - Storage space running low
    /// - Unsaved changes warning
    /// - Permission requests
    /// - Non-critical validation errors
    /// 
    /// ## Example:
    /// ```swift
    /// notification = .toastWarning("Storage almost full", haptic: .warning)
    /// ```
    case warning
    
    /// Error haptic feedback for failures and critical issues.
    /// 
    /// Provides a sharp, attention-demanding tactile sensation appropriate
    /// for errors, failures, and critical situations requiring immediate
    /// user attention. Uses the system's error notification pattern.
    /// 
    /// **Characteristics:**
    /// - Sharp, pronounced sensation
    /// - Immediately attention-getting
    /// - Negative emotional association
    /// - Maps to `UINotificationFeedbackGenerator.error` on iOS
    /// 
    /// **Use Cases:**
    /// - Network connection failed
    /// - Invalid form submission
    /// - Critical system errors
    /// - Security-related issues
    /// 
    /// ## Example:
    /// ```swift
    /// notification = .toastError("Upload failed", haptic: .error)
    /// ```
    case error
    
    // MARK: - Impact Feedback Types
    
    /// Light impact haptic feedback for subtle interactions.
    /// 
    /// Provides a gentle tactile sensation appropriate for light touches,
    /// selections, and subtle interface interactions. Ideal for frequent
    /// actions where stronger feedback would become overwhelming.
    /// 
    /// **Characteristics:**
    /// - Very subtle sensation
    /// - Minimal energy and duration
    /// - Suitable for frequent use
    /// - Maps to `UIImpactFeedbackGenerator(.light)` on iOS
    /// 
    /// **Use Cases:**
    /// - Minor UI state changes
    /// - Subtle confirmations
    /// - Progress updates
    /// - Non-critical informational messages
    /// 
    /// ## Example:
    /// ```swift
    /// notification = .toastInfo("3 new messages", haptic: .light)
    /// ```
    case light
    
    /// Medium impact haptic feedback for standard interactions.
    /// 
    /// Provides a balanced tactile sensation appropriate for most user
    /// interactions, selections, and standard interface actions. Offers
    /// good feedback without being overwhelming.
    /// 
    /// **Characteristics:**
    /// - Moderate sensation intensity
    /// - Balanced energy and duration
    /// - Versatile for various interaction types
    /// - Maps to `UIImpactFeedbackGenerator(.medium)` on iOS
    /// 
    /// **Use Cases:**
    /// - Button presses and selections
    /// - Mode switches and toggles
    /// - Standard confirmations
    /// - General user interface feedback
    /// 
    /// ## Example:
    /// ```swift
    /// notification = .toastInfo("Settings updated", haptic: .medium)
    /// ```
    case medium
    
    /// Heavy impact haptic feedback for significant interactions.
    /// 
    /// Provides a strong tactile sensation appropriate for important
    /// actions, significant changes, and high-impact interface interactions.
    /// Use sparingly to maintain impact and avoid user fatigue.
    /// 
    /// **Characteristics:**
    /// - Strong, pronounced sensation
    /// - High energy and longer duration
    /// - Reserved for important interactions
    /// - Maps to `UIImpactFeedbackGenerator(.heavy)` on iOS
    /// 
    /// **Use Cases:**
    /// - Important destructive actions
    /// - Significant mode changes
    /// - High-value confirmations
    /// - Critical notifications requiring strong attention
    /// 
    /// ## Example:
    /// ```swift
    /// notification = .toastError("Data will be permanently deleted", haptic: .heavy)
    /// ```
    case heavy
}

// MARK: - Haptic Triggering
public extension HapticFeedback {
    /// Triggers the haptic feedback on supported platforms.
    /// 
    /// Executes the appropriate haptic feedback pattern using the platform's
    /// native haptic feedback system. On unsupported platforms, this method
    /// has no effect and returns gracefully.
    /// 
    /// **Platform Behavior:**
    /// - **iOS**: Uses UIKit feedback generators for rich haptic feedback
    /// 
    /// **Performance Notes:**
    /// - Feedback generators are created on-demand for optimal performance
    /// - System respects user haptic preferences automatically
    /// - Gracefully handles disabled haptics or unsupported devices
    /// 
    /// ## Example:
    /// ```swift
    /// // Trigger haptic manually
    /// HapticFeedback.success.trigger()
    /// 
    /// // Trigger conditionally
    /// if operationSucceeded {
    ///     HapticFeedback.success.trigger()
    /// } else {
    ///     HapticFeedback.error.trigger()
    /// }
    /// ```
    @MainActor
    func trigger() {
        #if os(iOS)
        switch self {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        #endif
        // On non-iOS platforms, haptic feedback is not available, so this is a no-op
    }
}

// MARK: - Semantic Mapping
public extension HapticFeedback {
    /// Returns the recommended haptic feedback for a notification category.
    /// 
    /// Provides semantic mapping between notification types and appropriate
    /// haptic feedback patterns, ensuring consistent tactile experiences
    /// across different notification categories.
    /// 
    /// - Parameter category: The notification category to get haptic feedback for.
    /// - Returns: The recommended HapticFeedback for the given category.
    /// 
    /// **Mapping:**
    /// - `.success` → `.success`
    /// - `.error` → `.error`
    /// - `.warning` → `.warning`
    /// - `.info` → `.light`
    /// - `.custom` → `.medium`
    /// 
    /// ## Example:
    /// ```swift
    /// let haptic = HapticFeedback.forCategory(.success) // Returns .success
    /// let haptic = HapticFeedback.forCategory(.info)    // Returns .light
    /// ```
    static func forCategory(_ category: NotificationCategory) -> HapticFeedback {
        switch category {
        case .success:
            return .success
        case .error:
            return .error
        case .warning:
            return .warning
        case .info:
            return .light
        case .custom:
            return .medium
        }
    }
    
    /// Returns the recommended haptic feedback for a notification type.
    /// 
    /// Convenience method that extracts the category from a notification type
    /// and returns the appropriate haptic feedback pattern.
    /// 
    /// - Parameter notificationType: The notification type to get haptic feedback for.
    /// - Returns: The recommended HapticFeedback for the given notification type.
    /// 
    /// ## Example:
    /// ```swift
    /// let notification = NotificationType.success("Done!", style: .toast())
    /// let haptic = HapticFeedback.forNotificationType(notification) // Returns .success
    /// ```
    static func forNotificationType(_ notificationType: NotificationType) -> HapticFeedback {
        return forCategory(notificationType.category)
    }
}
