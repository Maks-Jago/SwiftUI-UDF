//===--- ShadowStyle.swift ---------------------------------===//
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

/// Shadow styling configuration for toast dialogs.
///
/// `ShadowStyle` controls the drop shadow effects applied to toast dialogs,
/// providing depth and visual separation from the background content. Shadows
/// can be completely disabled for flat designs or enhanced for stronger visual
/// hierarchy and better content separation.
///
/// ## Usage:
/// ```swift
/// // Disable shadows for flat design
/// let flatTheme = ToastTheme(shadow: .disabled)
/// 
/// // Use preset shadow styles
/// let subtleTheme = ToastTheme(shadow: .subtle)
/// let strongTheme = ToastTheme(shadow: .strong)
/// 
/// // Custom shadow configuration
/// let customShadow = ShadowStyle.enabled(
///     radius: 6,
///     opacity: 0.15,
///     offset: CGPoint(x: 0, y: 3)
/// )
/// let customTheme = ToastTheme(shadow: customShadow)
/// ```
public enum ShadowStyle: Hashable, Sendable {
    
    /// No shadow effect applied to toast dialogs.
    ///
    /// Creates a completely flat appearance without any depth effects.
    /// Ideal for modern, minimalist design systems that emphasize
    /// flat design principles and clean visual hierarchy.
    /// 
    /// ## Use Cases:
    /// - Minimalist or flat design aesthetics
    /// - High-density interfaces where shadows might create visual clutter
    /// - Accessibility scenarios where reduced visual effects are preferred
    /// - Performance-sensitive contexts where shadow rendering should be avoided
    /// 
    /// ## Example:
    /// ```swift
    /// let flatTheme = ToastTheme(shadow: .disabled)
    /// ```
    case disabled
    
    /// Enabled shadow with customizable parameters.
    /// 
    /// Applies a drop shadow effect with full control over blur radius,
    /// opacity, and position offset. This creates visual depth and
    /// separation between the toast and background content.
    /// 
    /// - Parameters:
    ///   - radius: The blur radius of the shadow in points. Larger values create softer, more diffused shadows.
    ///   - opacity: The transparency of the shadow (0.0 to 1.0). Lower values create subtle effects.
    ///   - offset: The X/Y displacement of the shadow from the toast. Positive Y values create downward shadows.
    /// 
    /// ## Design Guidelines:
    /// - **Radius**: 2-4pt for subtle depth, 6-8pt for pronounced separation, 10pt+ for dramatic effects
    /// - **Opacity**: 0.05-0.1 for subtle shadows, 0.1-0.2 for standard depth, 0.2+ for strong emphasis
    /// - **Offset**: (0, 1-2) for subtle lift, (0, 2-4) for standard elevation, (0, 4+) for floating effects
    /// 
    /// ## Example:
    /// ```swift
    /// // Subtle depth
    /// let subtle = ShadowStyle.enabled(radius: 2, opacity: 0.05, offset: CGPoint(x: 0, y: 1))
    /// 
    /// // Standard shadow
    /// let standard = ShadowStyle.enabled(radius: 4, opacity: 0.1, offset: CGPoint(x: 0, y: 2))
    /// 
    /// // Strong emphasis
    /// let strong = ShadowStyle.enabled(radius: 8, opacity: 0.2, offset: CGPoint(x: 0, y: 4))
    /// ```
    case enabled(radius: CGFloat = 4, opacity: Double = 0.1, offset: CGPoint = CGPoint(x: 0, y: 2))
}

// MARK: - Preset Shadow Styles
public extension ShadowStyle {
    /// Default shadow style with balanced visual depth.
    /// 
    /// Provides moderate shadow effects suitable for most design contexts.
    /// Creates noticeable but not overwhelming depth that works well across
    /// different background colors and interface densities.
    /// 
    /// **Configuration:**
    /// - Radius: 4pt (moderate blur)
    /// - Opacity: 0.1 (10% transparency)
    /// - Offset: (0, 2) (subtle downward displacement)
    /// 
    /// ## Example:
    /// ```swift
    /// let theme = ToastTheme(shadow: .default)
    /// // Equivalent to: .enabled(radius: 4, opacity: 0.1, offset: CGPoint(x: 0, y: 2))
    /// ```
    static let `default`: ShadowStyle = .enabled()
    
    /// Subtle shadow style with minimal visual impact.
    /// 
    /// Creates barely perceptible depth that provides gentle separation
    /// without drawing attention to the shadow effect itself. Perfect
    /// for interfaces that need subtle depth cues without visual distraction.
    /// 
    /// **Configuration:**
    /// - Radius: 2pt (minimal blur)
    /// - Opacity: 0.05 (5% transparency)
    /// - Offset: (0, 1) (minimal downward displacement)
    /// 
    /// ## Use Cases:
    /// - Refined, sophisticated interfaces
    /// - High-density information displays
    /// - Contexts where content should be emphasized over visual effects
    /// 
    /// ## Example:
    /// ```swift
    /// let refinedTheme = ToastTheme(shadow: .subtle)
    /// ```
    static let subtle: ShadowStyle = .enabled(radius: 2, opacity: 0.05, offset: CGPoint(x: 0, y: 1))
    
    /// Strong shadow style with pronounced visual depth.
    /// 
    /// Creates prominent shadow effects that provide clear visual separation
    /// and emphasis. Ideal for situations where toasts need to stand out
    /// prominently from complex or visually busy backgrounds.
    /// 
    /// **Configuration:**
    /// - Radius: 8pt (pronounced blur)
    /// - Opacity: 0.2 (20% transparency)
    /// - Offset: (0, 4) (noticeable downward displacement)
    /// 
    /// ## Use Cases:
    /// - Critical dialogs that need maximum attention
    /// - Complex backgrounds where strong separation is needed
    /// - Dramatic or high-impact design aesthetics
    /// - Situations where toast visibility is paramount
    /// 
    /// ## Example:
    /// ```swift
    /// let dramaticTheme = ToastTheme(shadow: .strong)
    /// ```
    static let strong: ShadowStyle = .enabled(radius: 8, opacity: 0.2, offset: CGPoint(x: 0, y: 4))
    
    /// Extra subtle shadow for ultra-minimal designs.
    /// 
    /// Provides the slightest possible depth effect while still maintaining
    /// visual separation. Perfect for ultra-clean interfaces that need
    /// just a hint of dimensionality.
    /// 
    /// **Configuration:**
    /// - Radius: 1pt (minimal blur)
    /// - Opacity: 0.03 (3% transparency)
    /// - Offset: (0, 0.5) (barely perceptible displacement)
    /// 
    /// ## Example:
    /// ```swift
    /// let ultraMinimal = ToastTheme(shadow: .ultraSubtle)
    /// ```
    static let ultraSubtle: ShadowStyle = .enabled(radius: 1, opacity: 0.03, offset: CGPoint(x: 0, y: 0.5))
    
    /// Elevated shadow for floating appearance.
    /// 
    /// Creates a dramatic floating effect that makes toasts appear to
    /// hover significantly above the background content. Best used
    /// sparingly for maximum impact dialogs.
    ///
    /// **Configuration:**
    /// - Radius: 12pt (wide blur)
    /// - Opacity: 0.25 (25% transparency)
    /// - Offset: (0, 6) (significant downward displacement)
    /// 
    /// ## Example:
    /// ```swift
    /// let floatingTheme = ToastTheme(shadow: .elevated)
    /// ```
    static let elevated: ShadowStyle = .enabled(radius: 12, opacity: 0.25, offset: CGPoint(x: 0, y: 6))
}

// MARK: - Shadow Modification
public extension ShadowStyle {
    /// Creates a new shadow style with modified radius while preserving other parameters.
    /// 
    /// - Parameter radius: The new blur radius value.
    /// - Returns: A new ShadowStyle with updated radius, or .disabled if original was disabled.
    /// 
    /// ## Example:
    /// ```swift
    /// let softerShadow = ShadowStyle.default.withRadius(6)
    /// ```
    func withRadius(_ radius: CGFloat) -> ShadowStyle {
        switch self {
        case .disabled:
            return .disabled
        case .enabled(_, let opacity, let offset):
            return .enabled(radius: radius, opacity: opacity, offset: offset)
        }
    }
    
    /// Creates a new shadow style with modified opacity while preserving other parameters.
    /// 
    /// - Parameter opacity: The new opacity value (0.0 to 1.0).
    /// - Returns: A new ShadowStyle with updated opacity, or .disabled if original was disabled.
    /// 
    /// ## Example:
    /// ```swift
    /// let strongerShadow = ShadowStyle.default.withOpacity(0.15)
    /// ```
    func withOpacity(_ opacity: Double) -> ShadowStyle {
        switch self {
        case .disabled:
            return .disabled
        case .enabled(let radius, _, let offset):
            return .enabled(radius: radius, opacity: opacity, offset: offset)
        }
    }
    
    /// Creates a new shadow style with modified offset while preserving other parameters.
    /// 
    /// - Parameter offset: The new shadow offset position.
    /// - Returns: A new ShadowStyle with updated offset, or .disabled if original was disabled.
    /// 
    /// ## Example:
    /// ```swift
    /// let lowerShadow = ShadowStyle.default.withOffset(CGPoint(x: 0, y: 4))
    /// ```
    func withOffset(_ offset: CGPoint) -> ShadowStyle {
        switch self {
        case .disabled:
            return .disabled
        case .enabled(let radius, let opacity, _):
            return .enabled(radius: radius, opacity: opacity, offset: offset)
        }
    }
    
    /// Creates a new shadow style with modified vertical offset while preserving horizontal offset.
    /// 
    /// Convenience method for the common case of adjusting shadow "height" without
    /// affecting horizontal positioning.
    /// 
    /// - Parameter y: The new vertical offset value.
    /// - Returns: A new ShadowStyle with updated Y offset.
    /// 
    /// ## Example:
    /// ```swift
    /// let higherShadow = ShadowStyle.default.withVerticalOffset(3)
    /// ```
    func withVerticalOffset(_ y: CGFloat) -> ShadowStyle {
        switch self {
        case .disabled:
            return .disabled
        case .enabled(let radius, let opacity, let offset):
            return .enabled(radius: radius, opacity: opacity, offset: CGPoint(x: offset.x, y: y))
        }
    }
}
