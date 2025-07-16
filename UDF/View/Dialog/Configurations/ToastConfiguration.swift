//===--- ToastConfiguration.swift ---------------------------------===//
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

/// Configuration for toast dialog behavior and appearance.
///
/// `ToastConfiguration` provides comprehensive control over how toast dialogs
/// are displayed, animated, and behave. This includes theming, timing, user interaction,
/// positioning, visual presentation options, and queue management.
///
/// ## Usage:
/// ```swift
/// // Default configuration
/// let defaultConfig = ToastConfiguration()
/// 
/// // Custom configuration with queue settings
/// let customConfig = ToastConfiguration(
///     theme: .vibrant,
///     defaultDuration: 3.0,
///     position: .bottom
/// )
/// 
/// // Use with dialog
/// dialog = .init(success: "Done!", style: .toast(customConfig))
/// ```
public struct ToastConfiguration: Hashable, Sendable {

    // MARK: - Theme Properties
    
    /// The visual theme for toast appearance including colors, fonts, and styling.
    /// 
    /// Controls the overall visual treatment of the toast including background colors,
    /// text styling, shadows, corner radius, and other visual elements.
    public var theme: ToastTheme
    
    /// The position where toasts should appear on screen.
    /// 
    /// Supports standard positions (top, bottom, center) as well as custom positioning
    /// with specific alignment and offset values.
    public var position: ToastPosition
    
    /// Priority level for this toast
    public var priority: ToastPriority
    
    // MARK: - Behavior Properties
    
    /// The default duration (in seconds) for how long toasts remain visible.
    /// 
    /// - Note: Set to 0 for toasts that don't auto-dismiss and require manual dismissal.
    /// - Default: 2.0 seconds
    public var defaultDuration: TimeInterval
    
    /// Whether users can dismiss toasts by tapping on them.
    /// 
    /// When enabled, tapping anywhere on the toast will dismiss it immediately.
    /// This provides an intuitive way for users to quickly dismiss dialogs.
    /// - Default: true
    public var tapToDismiss: Bool
    
    /// Whether users can dismiss toasts using swipe gestures.
    /// 
    /// When enabled, swiping the toast in any direction will dismiss it.
    /// This follows platform conventions for dismissible UI elements.
    /// - Default: true
    public var swipeToDismiss: Bool
    
    // MARK: - Animation Properties
    
    /// The animation used for toast presentation and dismissal.
    /// 
    /// Controls the timing curve and duration of toast animations.
    /// Use spring animations for natural, responsive feel.
    /// - Default: Spring animation with 0.3s response and 0.6 damping
    public var animation: Animation
    
    /// The transition effect used when toasts appear and disappear.
    /// 
    /// Defines how toasts animate in and out of view. The transition automatically
    /// adapts based on the toast position (slide from edges, scale for center).
    /// - Default: Slide from top edge combined with opacity fade
    public nonisolated(unsafe) var transition: AnyTransition
    
    // MARK: - Layout Properties
    
    /// The maximum width constraint for toast dialogs.
    ///
    /// Prevents toasts from becoming too wide on larger screens while ensuring
    /// they remain readable and visually balanced.
    /// - Default: 600 points
    public var maxWidth: CGFloat
    
    /// The horizontal padding around toast content within the screen bounds.
    /// 
    /// Provides breathing room between toast edges and screen edges,
    /// ensuring toasts don't extend to the very edge of the display.
    /// - Default: 16 points
    public var horizontalPadding: CGFloat
    
    /// The text alignment within toast dialogs.
    ///
    /// Controls how text content is aligned within the toast container.
    /// Also affects icon positioning relative to the text content.
    /// - Default: .leading (left-aligned)
    public var textAlignment: HorizontalAlignment
    
    // MARK: - Initializer
    
    /// Creates a new toast configuration with the specified parameters.
    /// 
    /// All parameters have sensible defaults that work well for most use cases.
    /// You only need to specify the parameters you want to customize.
    /// 
    /// - Parameters:
    ///   - theme: The visual theme for toast appearance. Defaults to `.default`.
    ///   - position: Where toasts appear on screen. Defaults to `.top`.
    ///   - priority: Priority level for this toast. Defaults to `.medium`.
    ///   - defaultDuration: Auto-dismiss duration in seconds. Defaults to 2.0.
    ///   - tapToDismiss: Enable tap-to-dismiss behavior. Defaults to true.
    ///   - swipeToDismiss: Enable swipe-to-dismiss behavior. Defaults to true.
    ///   - animation: Animation for presentation/dismissal. Defaults to spring animation.
    ///   - transition: Transition effect for appearance. Defaults to slide from top.
    ///   - maxWidth: Maximum toast width constraint. Defaults to 600.
    ///   - horizontalPadding: Horizontal screen padding. Defaults to 16.
    ///   - textAlignment: Text alignment within toasts. Defaults to .leading.
    /// 
    /// ## Example:
    /// ```swift
    /// let config = ToastConfiguration(
    ///     theme: .vibrant,
    ///     position: .bottom,
    ///     defaultDuration: 3.0,
    ///     textAlignment: .center
    /// )
    /// ```
    public init(
        theme: ToastTheme = .default,
        position: ToastPosition = .top,
        priority: ToastPriority = .medium,
        defaultDuration: TimeInterval = 2.0,
        tapToDismiss: Bool = true,
        swipeToDismiss: Bool = true,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
        transition: AnyTransition = .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ),
        maxWidth: CGFloat = 600,
        horizontalPadding: CGFloat = 16,
        textAlignment: HorizontalAlignment = .leading
    ) {
        self.theme = theme
        self.position = position
        self.priority = priority
        self.defaultDuration = defaultDuration
        self.tapToDismiss = tapToDismiss
        self.swipeToDismiss = swipeToDismiss
        self.animation = animation
        self.transition = transition
        self.maxWidth = maxWidth
        self.horizontalPadding = horizontalPadding
        self.textAlignment = textAlignment
    }
    
    // MARK: - Equatable Implementation
    public static func == (lhs: ToastConfiguration, rhs: ToastConfiguration) -> Bool {
        return lhs.theme == rhs.theme &&
        lhs.position == rhs.position &&
        lhs.defaultDuration == rhs.defaultDuration &&
        lhs.tapToDismiss == rhs.tapToDismiss &&
        lhs.swipeToDismiss == rhs.swipeToDismiss &&
        lhs.maxWidth == rhs.maxWidth &&
        lhs.horizontalPadding == rhs.horizontalPadding &&
        lhs.textAlignment == rhs.textAlignment
    }
    
    // MARK: - Hashable Implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(theme)
        hasher.combine(position)
        hasher.combine(defaultDuration)
        hasher.combine(tapToDismiss)
        hasher.combine(swipeToDismiss)
        hasher.combine(maxWidth)
        hasher.combine(horizontalPadding)
    }
}

// MARK: - Preset Configurations
public extension ToastConfiguration {
    /// Default toast configuration with standard settings.
    /// 
    /// Provides a balanced configuration suitable for most applications:
    /// - Default theme with solid colors
    /// - Top positioning
    /// - 2-second auto-dismiss
    /// - Tap and swipe to dismiss enabled
    /// - Spring animation
    /// - Leading text alignment
    static let `default` = ToastConfiguration()
    
    /// Configuration optimized for bottom positioning.
    /// 
    /// Uses bottom slide transition and positioning suitable for bottom toasts:
    /// - Bottom positioning
    /// - Slide from bottom transition
    /// - Other settings match default
    static let bottom = ToastConfiguration(
        position: .bottom,
        transition: .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    )
    
    /// Configuration optimized for center positioning.
    /// 
    /// Uses scale transition and center alignment suitable for center toasts:
    /// - Center positioning
    /// - Scale transition with opacity
    /// - Center text alignment
    static let center = ToastConfiguration(
        position: .center,
        transition: .opacity.combined(with: .scale(scale: 0.9)),
        textAlignment: .center
    )
    
    /// Configuration with vibrant theme and enhanced visual appeal.
    /// 
    /// Uses gradient colors and enhanced visual settings:
    /// - Vibrant theme with gradients
    /// - Slightly longer duration for better visibility
    /// - Enhanced shadow effects
    static let vibrant = ToastConfiguration(
        theme: .vibrant,
        defaultDuration: 3.0
    )
    
    /// Configuration with subtle, minimal appearance.
    /// 
    /// Uses translucent colors and minimal visual effects:
    /// - Subtle theme with translucent backgrounds
    /// - Disabled shadows for minimal look
    /// - Shorter duration for quick feedback
    static let subtle = ToastConfiguration(
        theme: .subtle,
        defaultDuration: 1.5
    )
    
    /// Configuration for critical toasts that require immediate attention.
    static let critical = ToastConfiguration(
        priority: .critical,
        defaultDuration: 4.0
    )
    
    /// Configuration for high-priority toasts that should be displayed prominently.
    static let highPriority = ToastConfiguration(
        priority: .high,
        defaultDuration: 3.0
    )
    
    /// Configuration for medium-priority toasts with standard settings.
    static let lowPriority = ToastConfiguration(
        priority: .low,
        defaultDuration: 1.0
    )
}

// MARK: - Configuration Helpers
public extension ToastConfiguration {
    /// Creates a copy of this configuration with a different theme.
    /// 
    /// - Parameter theme: The new theme to apply.
    /// - Returns: A new configuration with the specified theme.
    func withTheme(_ theme: ToastTheme) -> ToastConfiguration {
        var config = self
        config.theme = theme
        return config
    }
    
    /// Creates a copy of this configuration with a different position.
    /// 
    /// - Parameter position: The new position to apply.
    /// - Returns: A new configuration with the specified position and appropriate transition.
    func withPosition(_ position: ToastPosition) -> ToastConfiguration {
        var config = self
        config.position = position
        
        // Update transition to match position
        switch position {
        case .top:
            config.transition = .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
        case .bottom:
            config.transition = .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        case .center, .custom:
            config.transition = .opacity.combined(with: .scale(scale: 0.9))
        }
        
        return config
    }
    
    /// Creates a copy of this configuration with a different duration.
    /// 
    /// - Parameter duration: The new auto-dismiss duration in seconds.
    /// - Returns: A new configuration with the specified duration.
    func withDuration(_ duration: TimeInterval) -> ToastConfiguration {
        var config = self
        config.defaultDuration = duration
        return config
    }
    
    /// Creates a copy of this configuration with dismissal behavior disabled.
    /// 
    /// Disables both tap and swipe dismissal, requiring manual dismissal via code.
    /// Useful for critical dialogs that must be explicitly handled.
    /// 
    /// - Returns: A new configuration with dismissal gestures disabled.
    func withoutDismissalGestures() -> ToastConfiguration {
        var config = self
        config.tapToDismiss = false
        config.swipeToDismiss = false
        return config
    }
}
