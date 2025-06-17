//===--- ColorStyle.swift ---------------------------------===//
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

/// Defines different color styling options for toast backgrounds.
///
/// `ColorStyle` provides flexible color treatments for toast dialogs,,
/// supporting both simple solid colors and dynamic gradient effects.
/// This enables rich visual theming while maintaining consistent APIs
/// across different color presentation styles.
///
/// ## Usage:
/// ```swift
/// // Solid color backgrounds
/// let errorStyle = ColorStyle.solid(.red)
/// let successStyle = ColorStyle.solid(.green)
/// 
/// // Gradient backgrounds
/// let vibrantError = ColorStyle.gradient([.red, .pink])
/// let vibrantSuccess = ColorStyle.gradient([.green, .mint])
/// 
/// // Use in themes
/// let theme = ToastTheme(
///     errorColors: .gradient([.red, .pink]),
///     successColors: .solid(.green)
/// )
/// ```
public enum ColorStyle: Hashable, Sendable {
    
    /// Solid color background using a single uniform color.
    /// 
    /// Provides simple, consistent color treatment suitable for most
    /// design systems. Supports all SwiftUI Color options including
    /// system colors, custom colors, and colors with opacity.
    /// 
    /// - Parameter color: The SwiftUI Color to use as background.
    /// 
    /// ## Examples:
    /// ```swift
    /// .solid(.red)                    // Standard red
    /// .solid(.red.opacity(0.3))       // Translucent red
    /// .solid(Color.accentColor)       // System accent color
    /// .solid(Color(hex: "FF5733"))    // Custom hex color
    /// ```
    case solid(Color)
    
    /// Gradient background using multiple colors blended together.
    /// 
    /// Creates visually dynamic backgrounds with smooth color transitions.
    /// Gradients run horizontally from leading to trailing edge by default,
    /// providing consistent visual flow regardless of text direction.
    /// 
    /// - Parameter colors: Array of SwiftUI Colors to blend in the gradient.
    ///   Must contain at least one color. Single colors create uniform backgrounds.
    /// 
    /// ## Examples:
    /// ```swift
    /// .gradient([.red, .pink])           // Red to pink transition
    /// .gradient([.blue, .cyan, .mint])   // Multi-stop gradient
    /// .gradient([.orange])               // Single color (equivalent to solid)
    /// ```
    case gradient([Color])
    
    // MARK: - Background View Generation
    
    /// Generates a SwiftUI view representing this color style as a background.
    /// 
    /// Creates the appropriate view type (Color or LinearGradient) based on
    /// the color style variant. The resulting view can be used directly as
    /// a background modifier or within other view compositions.
    /// 
    /// - Returns: A SwiftUI view implementing the color style.
    /// 
    /// ## Implementation Details:
    /// - Solid colors return a direct Color view
    /// - Gradients create LinearGradient with horizontal flow (leading to trailing)
    /// - Empty gradient arrays default to clear color for safety
    /// 
    /// ## Example:
    /// ```swift
    /// let colorStyle = ColorStyle.gradient([.red, .pink])
    /// 
    /// // Use as background
    /// Text("Hello")
    ///     .background(colorStyle.background())
    /// ```
    @ViewBuilder
    func background() -> some View {
        switch self {
        case .solid(let color):
            color
        case .gradient(let colors):
            if colors.isEmpty {
                Color.clear
            } else if colors.count == 1 {
                colors[0]
            } else {
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
    
    // MARK: - Foreground Color Calculation
    
    /// Calculates the optimal foreground text color for this background style.
    /// 
    /// Automatically determines whether white or primary (black/dark) text
    /// provides better contrast and readability against the background color.
    /// This ensures text remains legible across different color themes.
    /// 
    /// - Returns: The recommended SwiftUI Color for text and icons.
    /// 
    /// ## Logic:
    /// - **Solid colors**: Returns white for non-clear colors, primary for clear/transparent
    /// - **Gradients**: Always returns white (conservative choice for gradient backgrounds)
    /// - **Clear/transparent**: Returns primary color to maintain visibility
    /// 
    /// ## Example:
    /// ```swift
    /// let style = ColorStyle.solid(.red)
    /// let textColor = style.foregroundColor  // Returns .white
    /// 
    /// Text("Error Message")
    ///     .foregroundColor(textColor)
    ///     .background(style.background())
    /// ```
    var foregroundColor: Color {
        switch self {
        case .solid(let color):
            return color.opacity(1) == Color.clear ? .primary : .white
        case .gradient:
            return .white
        }
    }
}

// MARK: - Convenience Initializers
public extension ColorStyle {
    /// Creates a solid color style from a system color name.
    /// 
    /// Provides convenient access to common system colors without
    /// needing to specify Color explicitly.
    /// 
    /// - Parameter systemColor: Standard SwiftUI system color.
    /// - Returns: A solid ColorStyle using the specified system color.
    /// 
    /// ## Example:
    /// ```swift
    /// let redStyle = ColorStyle.systemRed    // Equivalent to .solid(.red)
    /// let blueStyle = ColorStyle.systemBlue  // Equivalent to .solid(.blue)
    /// ```
    static var systemRed: ColorStyle { .solid(.red) }
    static var systemGreen: ColorStyle { .solid(.green) }
    static var systemBlue: ColorStyle { .solid(.blue) }
    static var systemOrange: ColorStyle { .solid(.orange) }
    static var systemYellow: ColorStyle { .solid(.yellow) }
    static var systemPink: ColorStyle { .solid(.pink) }
    static var systemPurple: ColorStyle { .solid(.purple) }
    static var systemTeal: ColorStyle { .solid(.teal) }
    static var systemIndigo: ColorStyle { .solid(.indigo) }
    static var systemMint: ColorStyle { .solid(.mint) }
    static var systemCyan: ColorStyle { .solid(.cyan) }
    static var systemBrown: ColorStyle { .solid(.brown) }
    static var systemGray: ColorStyle { .solid(.gray) }
    
    // Creates a clear/transparent color style.
    /// 
    /// Useful for creating transparent backgrounds where the underlying
    /// content should show through.
    /// 
    /// - Returns: A solid ColorStyle using clear color.
    static var clear: ColorStyle { .solid(.clear) }
}

// MARK: - Gradient Convenience Methods
public extension ColorStyle {
    /// Creates a two-color gradient from specified colors.
    /// 
    /// Convenience method for creating common two-color gradients
    /// without needing to specify an array explicitly.
    /// 
    /// - Parameters:
    ///   - from: Starting color of the gradient.
    ///   - to: Ending color of the gradient.
    /// - Returns: A gradient ColorStyle transitioning from first to second color.
    /// 
    /// ## Example:
    /// ```swift
    /// let errorGradient = ColorStyle.gradient(from: .red, to: .pink)
    /// let successGradient = ColorStyle.gradient(from: .green, to: .mint)
    /// ```
    static func gradient(from: Color, to: Color) -> ColorStyle {
        .gradient([from, to])
    }
    
    /// Creates a three-color gradient with a middle transition color.
    /// 
    /// Useful for creating more complex gradients with intermediate colors
    /// that provide richer visual transitions.
    /// 
    /// - Parameters:
    ///   - from: Starting color of the gradient.
    ///   - through: Middle color of the gradient.
    ///   - to: Ending color of the gradient.
    /// - Returns: A gradient ColorStyle with three color stops.
    /// 
    /// ## Example:
    /// ```swift
    /// let sunsetGradient = ColorStyle.gradient(from: .orange, through: .pink, to: .purple)
    /// ```
    static func gradient(from: Color, through: Color, to: Color) -> ColorStyle {
        .gradient([from, through, to])
    }
}
