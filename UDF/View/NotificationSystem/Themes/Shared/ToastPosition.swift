//===--- ToastPosition.swift ---------------------------------===//
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

/// Defines where toast notifications appear on screen.
///
/// `ToastPosition` controls the placement and positioning of toast notifications,
/// supporting both standard preset positions and fully customizable positioning
/// with precise alignment and offset control. This enables flexible toast
/// placement that adapts to different interface layouts and design requirements.
///
/// ## Usage:
/// ```swift
/// // Standard positions
/// let config = ToastConfiguration(position: .top)
/// let config = ToastConfiguration(position: .bottom)
/// let config = ToastConfiguration(position: .center)
/// 
/// // Custom positioning
/// let customPosition = ToastPosition.custom(
///     alignment: .topLeading,
///     offset: CGPoint(x: 20, y: 50)
/// )
/// let config = ToastConfiguration(position: customPosition)
/// ```
public enum ToastPosition: Hashable, Sendable {
    
    /// Top of the screen, centered horizontally.
    /// 
    /// Positions toasts at the top of the screen with automatic safe area
    /// consideration. This is the most common position for status updates
    /// and non-critical notifications that shouldn't interrupt user workflow.
    /// 
    /// **Characteristics:**
    /// - Appears below status bar and notch/dynamic island
    /// - Slides in from top edge with natural animation
    /// - Good for frequent, non-intrusive notifications
    /// - Follows platform conventions for system notifications
    /// 
    /// **Use Cases:**
    /// - Success confirmations ("File saved")
    /// - Status updates ("Sync complete")
    /// - Non-critical informational messages
    /// - Quick feedback for user actions
    /// 
    /// ## Example:
    /// ```swift
    /// let config = ToastConfiguration(position: .top)
    /// notification = .init(success: "Upload complete!", style: .toast(config))
    /// ```
    case top
    
    /// Bottom of the screen, centered horizontally.
    /// 
    /// Positions toasts at the bottom of the screen above tab bars and
    /// home indicators. Ideal for notifications that shouldn't obscure
    /// top navigation or when bottom placement provides better context.
    /// 
    /// **Characteristics:**
    /// - Appears above tab bars and home indicator
    /// - Slides in from bottom edge with natural animation
    /// - Less likely to interfere with navigation
    /// - Good for action-related feedback
    /// 
    /// **Use Cases:**
    /// - Action confirmations ("Item added to cart")
    /// - Undo operations with action buttons
    /// - Form validation messages
    /// - Context-sensitive feedback near bottom controls
    /// 
    /// ## Example:
    /// ```swift
    /// let config = ToastConfiguration(position: .bottom)
    /// notification = .init(warning: "Item deleted", style: .toast(config))
    /// ```
    case bottom
    
    /// Center of the screen, both horizontally and vertically.
    /// 
    /// Positions toasts in the exact center of the screen for maximum
    /// visibility and attention. Best reserved for critical notifications
    /// that require immediate user attention or acknowledgment.
    /// 
    /// **Characteristics:**
    /// - Maximum visibility and attention-grabbing
    /// - Scales in with opacity animation for smooth appearance
    /// - Can obscure content, so use sparingly
    /// - Creates modal-like focus without blocking interaction
    /// 
    /// **Use Cases:**
    /// - Critical error messages
    /// - Important system announcements
    /// - Loading states with progress indication
    /// - Achievement or milestone celebrations
    /// 
    /// ## Example:
    /// ```swift
    /// let config = ToastConfiguration(position: .center)
    /// notification = .init(error: "Network unavailable", style: .toast(config))
    /// ```
    case center
    
    /// Custom position with full control over alignment and offset.
    /// 
    /// Provides complete flexibility for toast positioning using SwiftUI's
    /// alignment system combined with pixel-perfect offset adjustments.
    /// Ideal for specialized interface layouts or design-specific requirements.
    /// 
    /// - Parameters:
    ///   - alignment: SwiftUI Alignment determining base position (e.g., .topLeading, .bottomTrailing)
    ///   - offset: CGPoint for fine-tuning position relative to alignment anchor
    /// 
    /// **Alignment Options:**
    /// - `.topLeading`, `.top`, `.topTrailing`
    /// - `.leading`, `.center`, `.trailing`  
    /// - `.bottomLeading`, `.bottom`, `.bottomTrailing`
    /// 
    /// **Offset Guidelines:**
    /// - Positive X: Move right, Negative X: Move left
    /// - Positive Y: Move down, Negative Y: Move up
    /// - Consider safe areas and device-specific layouts
    /// 
    /// ## Examples:
    /// ```swift
    /// // Top-right corner with padding
    /// let topRight = ToastPosition.custom(
    ///     alignment: .topTrailing,
    ///     offset: CGPoint(x: -20, y: 20)
    /// )
    /// 
    /// // Bottom-left with custom spacing
    /// let bottomLeft = ToastPosition.custom(
    ///     alignment: .bottomLeading,
    ///     offset: CGPoint(x: 20, y: -50)
    /// )
    /// 
    /// // Slightly off-center
    /// let offCenter = ToastPosition.custom(
    ///     alignment: .center,
    ///     offset: CGPoint(x: 0, y: -100)
    /// )
    /// ```
    case custom(alignment: Alignment, offset: CGPoint = .zero)
    
    // MARK: - Position Properties
    
    /// The SwiftUI alignment used for positioning this toast.
    /// 
    /// Returns the base alignment anchor point that determines where
    /// the toast appears before any offset adjustments are applied.
    /// 
    /// - Returns: SwiftUI Alignment corresponding to this position.
    /// 
    /// ## Values:
    /// - `.top` → `.top`
    /// - `.bottom` → `.bottom`
    /// - `.center` → `.center`
    /// - `.custom(alignment, _)` → custom alignment value
    var alignment: Alignment {
        switch self {
        case .top: .top
        case .bottom: .bottom
        case .center: .center
        case .custom(let alignment, _): alignment
        }
    }
    
    /// The pixel offset applied relative to the alignment anchor.
    /// 
    /// Returns the fine-tuning adjustment applied after the base
    /// alignment positioning. Zero offset means exact alignment positioning.
    /// 
    /// - Returns: CGPoint representing X/Y pixel adjustments.
    /// 
    /// ## Values:
    /// - Standard positions (`.top`, `.bottom`, `.center`) → `.zero`
    /// - `.custom(_, offset)` → custom offset value
    var offset: CGPoint {
        switch self {
        case .custom(_, let offset): offset
        default: .zero
        }
    }
    
    // MARK: - Hashable Conformance

    nonisolated public func hash(into hasher: inout Hasher) {
        switch self {
        case .top:
            hasher.combine("top")
        case .bottom:
            hasher.combine("bottom")
        case .center:
            hasher.combine("center")
        case .custom:
            hasher.combine("custom")
        }
    }
}

// MARK: - Position Utilities
public extension ToastPosition {
    /// Creates a new position with modified offset while preserving alignment.
    /// 
    /// Useful for creating variations of existing positions with
    /// different spacing or positioning adjustments.
    /// 
    /// - Parameter newOffset: The new offset to apply.
    /// - Returns: A new ToastPosition with updated offset.
    /// 
    /// ## Example:
    /// ```swift
    /// let shifted = ToastPosition.top.withOffset(CGPoint(x: 20, y: 10))
    /// ```
    func withOffset(_ newOffset: CGPoint) -> ToastPosition {
        .custom(alignment: alignment, offset: newOffset)
    }
    
    /// Creates a new position with additional offset applied to current offset.
    /// 
    /// Adds the specified offset to any existing offset, useful for
    /// fine-tuning positions or applying dynamic adjustments.
    /// 
    /// - Parameter additionalOffset: The offset to add to current offset.
    /// - Returns: A new ToastPosition with combined offset.
    /// 
    /// ## Example:
    /// ```swift
    /// let adjusted = position.adjustedBy(CGPoint(x: 0, y: -20))
    /// ```
    func adjustedBy(_ additionalOffset: CGPoint) -> ToastPosition {
        let currentOffset = offset
        let newOffset = CGPoint(
            x: currentOffset.x + additionalOffset.x,
            y: currentOffset.y + additionalOffset.y
        )
        return .custom(alignment: alignment, offset: newOffset)
    }
}
