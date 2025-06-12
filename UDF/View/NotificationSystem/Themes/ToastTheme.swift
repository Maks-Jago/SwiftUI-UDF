//===--- ToastTheme.swift ---------------------------------===//
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

/// Visual theme configuration for toast notifications.
///
/// `ToastTheme` defines the complete visual appearance of toast notifications,
/// including colors, typography, layout spacing, shadows, and other visual elements.
/// This provides comprehensive control over the aesthetic presentation while
/// maintaining consistency across different notification types.
///
/// ## Usage:
/// ```swift
/// // Use preset themes
/// let config = ToastConfiguration(theme: .vibrant)
/// let config = ToastConfiguration(theme: .subtle)
/// 
/// // Create custom theme
/// let customTheme = ToastTheme(
///     errorColors: .gradient([.red, .pink]),
///     successColors: .gradient([.green, .mint]),
///     messageFont: .title3,
///     cornerRadius: 16,
///     shadow: .strong
/// )
/// 
/// // Use with configuration
/// let config = ToastConfiguration(theme: customTheme)
/// ```
public struct ToastTheme: Hashable, Sendable {
    // MARK: - Color Properties
    
    /// Color styling for error/failure toast notifications.
    /// 
    /// Defines the background color treatment for error states. Can be solid colors
    /// or gradients. Should convey urgency and attention while remaining accessible.
    /// - Default: Solid red (.red)
    public var errorColors: ColorStyle
    
    /// Color styling for success toast notifications.
    /// 
    /// Defines the background color treatment for successful operations. Should
    /// convey positive feedback and completion while being visually pleasant.
    /// - Default: Solid green (.green)
    public var successColors: ColorStyle
    
    /// Color styling for warning toast notifications.
    /// 
    /// Defines the background color treatment for caution states. Should grab
    /// attention without being as urgent as error states.
    /// - Default: Solid orange (.orange)
    public var warningColors: ColorStyle
    
    /// Color styling for informational toast notifications.
    /// 
    /// Defines the background color treatment for neutral information. Should
    /// be noticeable but not alarming or overly attention-grabbing.
    /// - Default: Solid blue (.blue)
    public var infoColors: ColorStyle
    
    // MARK: - Typography Properties
    
    /// Font styling for the main message text in toast notifications.
    /// 
    /// Controls the primary text appearance. Should be highly legible and
    /// appropriately sized for quick reading during brief toast presentations.
    /// - Default: .headline
    public var messageFont: Font
    
    /// Font styling for action button text in toast notifications.
    /// 
    /// Controls the appearance of interactive button text. Should be clearly
    /// readable while being visually distinct from the main message.
    /// - Default: .callout with medium weight
    public var buttonFont: Font
    
    // MARK: - Layout Properties
    
    /// Internal padding around toast content.
    /// 
    /// Controls the spacing between the toast edges and the internal content
    /// (text, icons, buttons). Affects overall toast size and content breathing room.
    /// - Default: 12pt top/bottom, 16pt leading/trailing
    public var padding: EdgeInsets
    
    /// Corner radius for toast background shape.
    /// 
    /// Defines how rounded the toast corners appear. Larger values create
    /// more rounded rectangles, while 0 creates sharp corners.
    /// - Default: 12 points
    public var cornerRadius: CGFloat
    
    /// Shadow styling applied to toast notifications.
    /// 
    /// Controls drop shadow appearance for depth and separation from background.
    /// Can be disabled for flat designs or enhanced for stronger visual hierarchy.
    /// - Default: Default shadow style (enabled with subtle appearance)
    public var shadow: ShadowStyle
    
    /// Size of icons displayed within toast notifications.
    /// 
    /// Controls the point size of system images and custom icons. Should be
    /// balanced with text size for visual harmony and accessibility.
    /// - Default: 20 points
    public var iconSize: CGFloat
    
    // MARK: - Initializer
    
    /// Creates a new toast theme with the specified visual parameters.
    /// 
    /// All parameters have carefully chosen defaults that provide good visual
    /// hierarchy and accessibility. You only need to specify parameters you
    /// want to customize from the defaults.
    /// 
    /// - Parameters:
    ///   - errorColors: Color styling for error notifications. Defaults to solid red.
    ///   - successColors: Color styling for success notifications. Defaults to solid green.
    ///   - warningColors: Color styling for warning notifications. Defaults to solid orange.
    ///   - infoColors: Color styling for info notifications. Defaults to solid blue.
    ///   - messageFont: Font for main message text. Defaults to .headline.
    ///   - buttonFont: Font for button text. Defaults to .callout with medium weight.
    ///   - padding: Internal content padding. Defaults to 12pt vertical, 16pt horizontal.
    ///   - cornerRadius: Background corner radius. Defaults to 12 points.
    ///   - shadow: Shadow styling. Defaults to .default (subtle shadow).
    ///   - iconSize: Icon size in points. Defaults to 20 points.
    /// 
    /// ## Example:
    /// ```swift
    /// let theme = ToastTheme(
    ///     errorColors: .gradient([.red, .pink]),
    ///     messageFont: .title3,
    ///     cornerRadius: 16,
    ///     shadow: .strong
    /// )
    /// ```
    public init(
        errorColors: ColorStyle = .solid(.red),
        successColors: ColorStyle = .solid(.green),
        warningColors: ColorStyle = .solid(.orange),
        infoColors: ColorStyle = .solid(.blue),
        messageFont: Font = .headline,
        buttonFont: Font = .callout.weight(.medium),
        padding: EdgeInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16),
        cornerRadius: CGFloat = 12,
        shadow: ShadowStyle = .default,
        iconSize: CGFloat = 20
    ) {
        self.errorColors = errorColors
        self.successColors = successColors
        self.warningColors = warningColors
        self.infoColors = infoColors
        self.messageFont = messageFont
        self.buttonFont = buttonFont
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.iconSize = iconSize
    }
    
    // MARK: - Hashable Implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(errorColors)
        hasher.combine(successColors)
        hasher.combine(warningColors)
        hasher.combine(infoColors)
        hasher.combine(messageFont)
        hasher.combine(buttonFont)
        hasher.combine(cornerRadius)
        hasher.combine(shadow)
        hasher.combine(iconSize)
    }
}

// MARK: - Preset Themes
public extension ToastTheme {
    /// Default theme with solid colors and balanced visual hierarchy.
    /// 
    /// Provides a clean, professional appearance suitable for most applications:
    /// - Solid semantic colors (red, green, orange, blue)
    /// - Standard fonts (.headline for messages, .callout for buttons)
    /// - Moderate corner radius (12pt) and subtle shadow
    /// - Balanced padding for good content spacing
    static let `default` = ToastTheme()
    
    /// Vibrant theme with gradient colors for enhanced visual appeal.
    /// 
    /// Uses eye-catching gradient backgrounds for more dynamic presentation:
    /// - Gradient colors transitioning between related hues
    /// - Error: Red to pink gradient
    /// - Success: Green to mint gradient  
    /// - Warning: Orange to yellow gradient
    /// - Info: Blue to cyan gradient
    /// - Other properties match default theme
    static let vibrant = ToastTheme(
        errorColors: .gradient([.red, .pink]),
        successColors: .gradient([.green, .mint]),
        warningColors: .gradient([.orange, .yellow]),
        infoColors: .gradient([.blue, .cyan])
    )
    
    /// Subtle theme with muted colors for reduced visual impact.
    /// 
    /// Uses softer, muted backgrounds for less intrusive notifications while
    /// maintaining clear readability and proper color coding:
    /// - Moderately transparent semantic colors (30% opacity) for visibility
    /// - Maintains color coding while being visually restrained
    /// - Ideal for frequent notifications or when minimal distraction is desired
    /// - Text remains fully opaque for excellent readability
    static let subtle = ToastTheme(
        errorColors: .solid(.red.opacity(0.3)),
        successColors: .solid(.green.opacity(0.3)),
        warningColors: .solid(.orange.opacity(0.3)),
        infoColors: .solid(.blue.opacity(0.3))
    )
    
    // High contrast theme optimized for accessibility.
    /// 
    /// Uses strong color contrast and larger text for improved accessibility:
    /// - Higher contrast color combinations
    /// - Larger font sizes for better readability
    /// - Enhanced shadow for better separation
    /// - Slightly larger icons for improved visibility
    static let highContrast = ToastTheme(
        errorColors: .solid(.red),
        successColors: .solid(.green),
        warningColors: .solid(.orange),
        infoColors: .solid(.blue),
        messageFont: .title3.weight(.semibold),
        buttonFont: .callout.weight(.bold),
        shadow: .strong,
        iconSize: 24
    )
    
    /// Minimal theme with no shadows and clean typography.
    /// 
    /// Provides a flat, modern appearance without visual effects:
    /// - Disabled shadows for completely flat appearance
    /// - Clean typography with standard weights
    /// - Suitable for modern, minimalist design systems
    static let minimal = ToastTheme(
        messageFont: .subheadline,
        buttonFont: .caption.weight(.medium),
        cornerRadius: 8,
        shadow: .disabled
    )
}

// MARK: - Theme Utilities
public extension ToastTheme {
    /// Returns the appropriate color style for the specified notification category.
    /// 
    /// Maps notification types to their corresponding color treatments defined
    /// in this theme. Custom notifications default to a neutral gray color.
    /// 
    /// - Parameter category: The notification category to get colors for.
    /// - Returns: The corresponding ColorStyle for the given category.
    /// 
    /// ## Example:
    /// ```swift
    /// let theme = ToastTheme.vibrant
    /// let successColors = theme.colorStyle(for: .success) // Returns gradient green to mint
    /// ```
    func colorStyle(for category: NotificationCategory) -> ColorStyle {
        switch category {
        case .error:
            return errorColors
        case .success:
            return successColors
        case .warning:
            return warningColors
        case .info:
            return infoColors
        case .custom:
            return .solid(.gray) // Neutral default for custom notifications
        }
    }
    
    /// Creates a copy of this theme with different color treatments.
    /// 
    /// Allows easy customization of color schemes while preserving other
    /// theme properties like typography and layout.
    /// 
    /// - Parameters:
    ///   - errorColors: New error color styling.
    ///   - successColors: New success color styling.
    ///   - warningColors: New warning color styling.
    ///   - infoColors: New info color styling.
    /// - Returns: A new theme with updated colors.
    func withColors(
        error errorColors: ColorStyle? = nil,
        success successColors: ColorStyle? = nil,
        warning warningColors: ColorStyle? = nil,
        info infoColors: ColorStyle? = nil
    ) -> ToastTheme {
        ToastTheme(
            errorColors: errorColors ?? self.errorColors,
            successColors: successColors ?? self.successColors,
            warningColors: warningColors ?? self.warningColors,
            infoColors: infoColors ?? self.infoColors,
            messageFont: messageFont,
            buttonFont: buttonFont,
            padding: padding,
            cornerRadius: cornerRadius,
            shadow: shadow,
            iconSize: iconSize
        )
    }
    
    /// Creates a copy of this theme with different typography.
    /// 
    /// Allows easy customization of font choices while preserving other
    /// theme properties like colors and layout.
    /// 
    /// - Parameters:
    ///   - messageFont: New font for message text.
    ///   - buttonFont: New font for button text.
    /// - Returns: A new theme with updated typography.
    func withTypography(
        messageFont: Font? = nil,
        buttonFont: Font? = nil
    ) -> ToastTheme {
        ToastTheme(
            errorColors: errorColors,
            successColors: successColors,
            warningColors: warningColors,
            infoColors: infoColors,
            messageFont: messageFont ?? self.messageFont,
            buttonFont: buttonFont ?? self.buttonFont,
            padding: padding,
            cornerRadius: cornerRadius,
            shadow: shadow,
            iconSize: iconSize
        )
    }
    
    /// Creates a copy of this theme with different layout properties.
    /// 
    /// Allows easy customization of spacing and visual effects while
    /// preserving colors and typography.
    /// 
    /// - Parameters:
    ///   - padding: New internal content padding.
    ///   - cornerRadius: New corner radius for background shape.
    ///   - shadow: New shadow styling.
    ///   - iconSize: New icon size in points.
    /// - Returns: A new theme with updated layout properties.
    func withLayout(
        padding: EdgeInsets? = nil,
        cornerRadius: CGFloat? = nil,
        shadow: ShadowStyle? = nil,
        iconSize: CGFloat? = nil
    ) -> ToastTheme {
        ToastTheme(
            errorColors: errorColors,
            successColors: successColors,
            warningColors: warningColors,
            infoColors: infoColors,
            messageFont: messageFont,
            buttonFont: buttonFont,
            padding: padding ?? self.padding,
            cornerRadius: cornerRadius ?? self.cornerRadius,
            shadow: shadow ?? self.shadow,
            iconSize: iconSize ?? self.iconSize
        )
    }
}
