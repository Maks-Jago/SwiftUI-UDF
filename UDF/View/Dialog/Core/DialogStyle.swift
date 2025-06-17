//===--- DialogStyle.swift ---------------------------------===//
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
import SwiftUI

/// Defines how a dialog should be presented to the user.
///
/// `DialogStyle` determines the presentation method and visual treatment
/// of dialogs. Each style has different capabilities and behavior patterns.
///
/// ## Available Styles:
/// - `.alert` - Native iOS system alerts using UIAlertController
/// - `.toast` - Custom overlay dialogs with full theming support
/// - `.confirmationDialog` - Native confirmation dialogs with no theming
///
/// ## Usage:
/// ```swift
/// // Alert style (Phase 1)
/// let dialog = DialogType.success("Message", style: .alert)
///
/// // Toast style (Phase 2)
/// let dialog = DialogType.success("Message", style: .toast())
///
/// // Confirmation dialog style (Phase 3)
/// dialog = .init(style: .confirmationDialog(config)) {
/// DialogContent("Share Photo") {
///     DialogButton.default("AirDrop") {
///         print("Sharing via AirDrop")
///     }
///     DialogButton.default("Messages") {
///         print("Sharing via Messages")
///     }
///     DialogButton.default("Mail") {
///         print("Sharing via Mail")
///     }
///     DialogButton.default("Save to Files") {
///         print("Saving to Files")
///     }
///     DialogButton.cancel("Cancel")
/// }
/// }
///
/// // Toast with custom configuration
/// let dialog = DialogType.success("Message", style: .toast(
///     ToastConfiguration(position: .bottom, theme: .vibrant)
/// ))
/// ```
public enum DialogStyle: Hashable, Sendable {
    case alert
    case toast(ToastConfiguration = .default)
    case confirmationDialog(ConfirmationDialogConfiguration = .default)
    
    // MARK: - Properties
    /// Whether this style supports custom theming.
    public var supportsTheming: Bool {
        switch self {
        case .alert, .confirmationDialog:
            return false
        case .toast:
            return true
        }
    }
    
    /// Whether this style is modal (blocks user interaction with underlying content).
    public var isModal: Bool {
        switch self {
        case .alert, .confirmationDialog:
            return true
        case .toast:
            return false
        }
    }
    
    /// Whether this style supports text input fields.
    public var supportsTextFields: Bool {
        switch self {
        case .alert:
            return true
        case .toast, .confirmationDialog:
            return false
        }
    }
    
    /// The presentation context for this style.
    public var presentationContext: PresentationContext {
        switch self {
        case .alert, .confirmationDialog:
            return .modal
        case .toast:
            return .overlay
        }
    }
    
    // MARK: - Equatable Implementation
    public static func == (lhs: DialogStyle, rhs: DialogStyle) -> Bool {
        switch (lhs, rhs) {
        case (.alert, .alert):
            return true
        case (.toast(let lhsConfig), .toast(let rhsConfig)):
            return lhsConfig == rhsConfig
        case (.confirmationDialog(let lhsConfig), .confirmationDialog(let rhsConfig)):
            return lhsConfig == rhsConfig
        default:
            return false
        }
    }
    
    // MARK: - Hashable Implementation
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .alert:
            hasher.combine("alert")
        case .toast(let config):
            hasher.combine("toast")
            hasher.combine(config)
        case .confirmationDialog(let config):
            hasher.combine("confirmationDialog")
            hasher.combine(config)
        }
    }
}

// MARK: - PresentationContext
/// Describes how a dialog style is presented to the user.
public enum PresentationContext: Equatable {
    /// Modal presentation that blocks interaction with underlying content.
    case modal
    
    /// Overlay presentation that appears on top but allows interaction underneath.
    case overlay
    
    /// Custom presentation with specific positioning and behavior.
    case custom
}
