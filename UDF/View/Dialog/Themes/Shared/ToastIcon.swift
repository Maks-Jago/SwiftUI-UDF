//===--- ToastIcon.swift ---------------------------------===//
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

/// Defines the icon representation for toast dialogs.
///
/// `ToastIcon` provides flexible icon options for toast dialogs, supporting
/// system images (SF Symbols), custom bundle images, arbitrary SwiftUI views,
/// or no icon at all. This enables rich visual customization while maintaining
/// consistent APIs across different icon types.
///
/// ## Usage:
/// ```swift
/// // System image (SF Symbol)
/// let successIcon = ToastIcon.systemImage("checkmark.circle.fill")
/// 
/// // Custom image from app bundle
/// let customIcon = ToastIcon.image("custom-success-icon")
/// 
/// // Custom SwiftUI view
/// let viewIcon = ToastIcon.view(AnyView(
///     Circle()
///         .fill(.green)
///         .frame(width: 20, height: 20)
/// ))
/// 
/// // No icon
/// let noIcon = ToastIcon.none
/// ```
@MainActor
public enum ToastIcon: Hashable {
    
    /// No icon displayed in the toast dialog.
    ///
    /// Use this option when the toast content should be purely textual without
    /// any visual icon accompaniment. This creates a cleaner, more minimal
    /// appearance focused entirely on the message content.
    /// 
    /// ## Example:
    /// ```swift
    /// let toast = Toast(
    ///     type: .info,
    ///     message: "Settings updated",
    ///     icon: .none
    /// )
    /// ```
    case none
    
    /// A system image using SF Symbols.
    /// 
    /// Displays an icon using Apple's SF Symbols system, providing access to
    /// thousands of professionally designed symbols that automatically adapt
    /// to different weights, sizes, and accessibility settings.
    /// 
    /// - Parameter symbolName: The SF Symbol name (e.g., "checkmark.circle.fill").
    /// 
    /// ## Examples:
    /// ```swift
    /// .systemImage("checkmark.circle.fill")    // Success checkmark
    /// .systemImage("xmark.circle.fill")        // Error X mark
    /// .systemImage("exclamationmark.triangle.fill") // Warning triangle
    /// .systemImage("info.circle.fill")         // Information icon
    /// .systemImage("wifi.slash")               // Network error
    /// ```
    case systemImage(String)
    
    /// A custom image from the app bundle.
    /// 
    /// Displays an icon using a custom image file included in your app's bundle.
    /// This enables branded or specialized iconography that isn't available
    /// in the SF Symbols collection.
    /// 
    /// - Parameter imageName: The name of the image file in the app bundle.
    /// 
    /// ## Examples:
    /// ```swift
    /// .image("company-logo")           // Brand-specific icon
    /// .image("custom-success-badge")   // Custom success indicator
    /// .image("achievement-trophy")     // Achievement dialog icon
    /// ```
    /// 
    /// ## Requirements:
    /// - Image must exist in the app bundle
    /// - Consider providing @2x and @3x variants for different screen densities
    /// - Ensure appropriate contrast for dialog backgrounds
    /// - Recommended size: 20-24pt at @1x resolution
    case image(String)
    
    /// A custom SwiftUI view as an icon.
    /// 
    /// Displays any arbitrary SwiftUI view as the dialog icon, providing
    /// maximum flexibility for complex iconography, animations, or branded
    /// visual elements that can't be achieved with static images.
    /// 
    /// - Parameter view: The SwiftUI view to display as an icon.
    /// 
    /// ## Examples:
    /// ```swift
    /// // Animated progress indicator
    /// .view(AnyView(
    ///     ProgressView()
    ///         .progressViewStyle(CircularProgressViewStyle(tint: .white))
    ///         .scaleEffect(0.8)
    /// ))
    /// 
    /// // Custom colored shape
    /// .view(AnyView(
    ///     RoundedRectangle(cornerRadius: 4)
    ///         .fill(.purple)
    ///         .frame(width: 16, height: 16)
    /// ))
    /// 
    /// // Complex branded icon
    /// .view(AnyView(CompanyLogoView()))
    /// ```
    /// 
    /// ## Performance Considerations:
    /// - Keep view complexity minimal for smooth animation performance
    /// - Avoid heavy computations or network calls in view content
    /// - Consider caching complex views when used frequently
    case view(AnyView)
    
    // MARK: - Equatable Implementation
    /// Compares two `ToastIcon` instances for equality.
    /// 
    /// Two toast icons are considered equal if they represent the same icon type
    /// and content. Note that view-based icons are compared by type only, as
    /// SwiftUI views cannot be meaningfully compared for content equality.
    /// 
    /// - Parameters:
    ///   - lhs: The left-hand side icon to compare.
    ///   - rhs: The right-hand side icon to compare.
    /// - Returns: `true` if the icons are equivalent, `false` otherwise.
    /// 
    /// ## Comparison Logic:
    /// - `.none` == `.none` → Always true
    /// - `.systemImage(name1)` == `.systemImage(name2)` → True if names match
    /// - `.image(name1)` == `.image(name2)` → True if names match  
    /// - `.view(_)` == `.view(_)` → Always true (content cannot be compared)
    /// - Different cases → Always false
    nonisolated public static func == (lhs: ToastIcon, rhs: ToastIcon) -> Bool {
        switch (lhs, rhs) {
        case (.systemImage(let lhsName), .systemImage(let rhsName)):
            return lhsName == rhsName
        case (.image(let lhsName), .image(let rhsName)):
            return lhsName == rhsName
        case (.view, .view):
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Initializers
public extension ToastIcon {
    /// Creates a system image icon with the specified SF Symbol name.
    /// 
    /// Convenience method for creating system image icons with improved readability
    /// and discoverability in code completion.
    /// 
    /// - Parameter symbolName: The SF Symbol name.
    /// - Returns: A `ToastIcon` configured with the specified system image.
    /// 
    /// ## Example:
    /// ```swift
    /// let icon = ToastIcon.system("checkmark.circle.fill")
    /// // Equivalent to: ToastIcon.systemImage("checkmark.circle.fill")
    /// ```
    static func system(_ symbolName: String) -> ToastIcon {
        .systemImage(symbolName)
    }
    
    /// Creates a custom view icon from any SwiftUI view.
    /// 
    /// Convenience method that automatically wraps the provided view in `AnyView`,
    /// simplifying the creation of view-based icons.
    /// 
    /// - Parameter content: A closure that returns the SwiftUI view to use as an icon.
    /// - Returns: A `ToastIcon` configured with the specified view content.
    /// 
    /// ## Example:
    /// ```swift
    /// let icon = ToastIcon.custom {
    ///     Circle()
    ///         .fill(.blue)
    ///         .frame(width: 20, height: 20)
    /// }
    /// ```
    static func custom<Content: View>(@ViewBuilder content: () -> Content) -> ToastIcon {
        .view(AnyView(content()))
    }
}

// MARK: - Semantic Icon Presets
public extension ToastIcon {
    /// Standard success icon using SF Symbols.
    /// 
    /// Provides a consistent success icon across the application using the
    /// standard checkmark symbol with filled circle background.
    static let success = ToastIcon.systemImage("checkmark.circle.fill")
    
    /// Standard error icon using SF Symbols.
    /// 
    /// Provides a consistent error icon across the application using the
    /// standard X mark symbol with filled circle background.
    static let error = ToastIcon.systemImage("xmark.circle.fill")
    
    /// Standard warning icon using SF Symbols.
    /// 
    /// Provides a consistent warning icon across the application using the
    /// standard exclamation mark in triangle symbol.
    static let warning = ToastIcon.systemImage("exclamationmark.triangle.fill")
    
    /// Standard informational icon using SF Symbols.
    /// 
    /// Provides a consistent info icon across the application using the
    /// standard information symbol with filled circle background.
    static let info = ToastIcon.systemImage("info.circle.fill")
    
    /// Network-related error icon using SF Symbols.
    /// 
    /// Specialized icon for network connectivity issues and related errors.
    static let networkError = ToastIcon.systemImage("wifi.slash")
    
    /// Loading or processing icon using SF Symbols.
    /// 
    /// Indicates ongoing operations, loading states, or processing activities.
    static let loading = ToastIcon.systemImage("arrow.triangle.2.circlepath")
    
    /// Download completion icon using SF Symbols.
    /// 
    /// Indicates successful download operations and file transfers.
    static let download = ToastIcon.systemImage("arrow.down.circle.fill")
    
    /// Upload completion icon using SF Symbols.
    /// 
    /// Indicates successful upload operations and file transfers.
    static let upload = ToastIcon.systemImage("arrow.up.circle.fill")
}

// MARK: - Hashable Implementation
extension ToastIcon {
    /// Generates a hash value for the toast icon.
    /// 
    /// Enables `ToastIcon` to be used in sets, as dictionary keys, and in other
    /// contexts requiring hashable types. Hash values are generated based on
    /// the icon type and associated content.
    /// 
    /// - Parameter hasher: The hasher to use for generating the hash value.
    nonisolated public func hash(into hasher: inout Hasher) {
        switch self {
        case .none:
            hasher.combine(0)
        case .systemImage(let name):
            hasher.combine(1)
            hasher.combine(name)
        case .image(let name):
            hasher.combine(2)
            hasher.combine(name)
        case .view:
            hasher.combine(3)
        }
    }
}
