//===--- ToastView.swift ----------------------------------===//
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

/// The main view component for rendering toast dialogs.
///
/// `ToastView` is responsible for displaying toast dialogs with full visual
/// customization, interactive gestures, and adaptive layout. It handles both
/// standard toast content (message + optional buttons) and completely custom
/// SwiftUI views, providing a flexible foundation for rich dialog experiences.
///
/// ## Features:
/// - **Gesture Support**: Tap and swipe to dismiss functionality
/// - **Flexible Layout**: Supports leading, center, and trailing text alignment
/// - **Custom Content**: Can display arbitrary SwiftUI views
/// - **Theming**: Full visual customization through ToastTheme
/// - **Interactive Elements**: Support for action buttons with various roles
/// - **Accessibility**: Semantic colors and proper contrast handling
///
/// ## Usage:
/// ```swift
/// ToastView(
///     toast: toast,
///     configuration: config,
///     onDismiss: { 
///         // Handle toast dismissal
///     }
/// )
/// ```
///
/// **Note**: This view is typically used internally by the dialog system
/// and not directly instantiated by application code.
struct ToastView: View {

    // MARK: - Properties
    
    /// The toast data containing message, type, and configuration.
    let toast: DialogTypeProtocol

    /// The configuration controlling toast behavior and appearance.
    let configuration: ToastConfiguration
    
    /// Callback executed when the toast should be dismissed.
    let onDismiss: () -> Void

    /// The icon view builder for the toast.
    let icon: () -> AnyView

    /// The custom content view builder for the toast, if any.
    let content: () -> AnyView?

    // MARK: - State

    init(
        toast: DialogTypeProtocol,
        configuration: ToastConfiguration,
        onDismiss: @escaping () -> Void
    ) {
        self.toast = toast
        self.configuration = configuration
        self.onDismiss = onDismiss
        self.icon = {
            let image: AnyView = switch toast.category {
            case .success: AnyView(Image(systemName: "checkmark.circle.fill"))
            case .error: AnyView(Image(systemName: "exclamationmark.triangle.fill"))
            case .warning: AnyView(Image(systemName: "exclamationmark.triangle.fill"))
            case .info: AnyView(Image(systemName: "info.circle.fill"))
            case .custom:
                {
                    if case let .custom(content, _) as DialogCustomType<AnyView, AnyView> = toast, let iconView = content.iconView?() {
                        iconView
                    } else {
                        AnyView(EmptyView())
                    }
                }()
            }
            return AnyView(image)
        }
        self.content = {
            if case let .custom(content, _) as DialogCustomType<AnyView, AnyView> = toast, let contentView = content.customContentView?() {
                contentView
            } else {
                AnyView(EmptyView())
            }
        }
        self.dragOffset = dragOffset
    }

    /// Current drag offset for swipe-to-dismiss gesture tracking.
    @State private var dragOffset: CGSize = .zero
    
    /// Indicates whether the user is currently dragging the toast.
    @GestureState private var isDragging: Bool = false
    
    // MARK: - Computed Properties
    
    /// Quick access to the theme configuration from the toast configuration.
    var theme: ToastTheme {
        configuration.theme
    }
    
    /// The main message text to display in the toast.
    ///
    /// Extracts the appropriate message content from the dialog type,
    /// handling both simple message dialogs and complex content dialogs.
    var displayMessage: String {
        if let message = toast.message {
            return message
        }
        
        return ""
    }
    
    /// Action buttons to display in the toast.
    ///
    /// Extracts action buttons from custom content dialogs.
    /// Simple message dialogs don't have action buttons.
    var actionButtons: [DialogButton] {
        toast.actions.compactMap { $0 as? DialogButton }
    }

    // MARK: - Body
    
    /// The main view body that renders the complete toast interface.
    ///
    /// Decides between custom content (if provided) or standard toast layout,
    /// then applies gestures, positioning, and interactive behaviors.    
    var body: some View {
        Group {
            if let customContent = content() {
                customContent
            } else {
                standardToastContent
            }
        }
        .offset(dragOffset)
        .gesture(dismissGestures)
        .onTapGesture {
            if configuration.tapToDismiss {
                onDismiss()
            }
        }
    }
}

// MARK: - Standard Toast Content
private extension ToastView {
    /// The standard toast layout with message, icons, and buttons.
    ///
    /// Creates a horizontally-arranged layout with flexible content positioning
    /// based on text alignment settings. Applies theming for background colors,
    /// corner radius, shadows, and other visual treatments.
    ///
    /// ## Layout Structure:
    /// ```
    /// [Leading Content] [Main Content] [Trailing Content]
    /// ```
    ///
    /// - **Leading Content**: Icons (for leading alignment) or spacers
    /// - **Main Content**: Text message and optional button row
    /// - **Trailing Content**: Icons (for trailing alignment) or spacers
    var standardToastContent: some View {
        HStack(spacing: 12) {
            leadingContent
            mainContent
            trailingContent
        }
        .padding(theme.padding)
        .frame(maxWidth: configuration.maxWidth)
        .background(
            theme.colorStyle(for: toast.category).background()
                .cornerRadius(theme.cornerRadius)
        )
        .applyShadow(theme.shadow)
    }
}

// MARK: - Gesture Handling
private extension ToastView {
    /// Drag gesture for swipe-to-dismiss functionality.
    ///
    /// Implements intuitive swipe-to-dismiss behavior with threshold-based
    /// dismissal and spring-back animation for incomplete swipes.
    ///
    /// ## Behavior:
    /// 1. **Active Dragging**: Toast follows finger movement with real-time offset
    /// 2. **Threshold Check**: Dismisses if swipe distance exceeds 100 points
    /// 3. **Spring Back**: Returns to original position for insufficient swipes
    /// 4. **Conditional**: Only active if `swipeToDismiss` is enabled and toast is dismissible
    ///
    /// ## Gesture Parameters:
    /// - **Threshold**: 100 points in any direction
    /// - **Spring Animation**: Natural bounce-back for incomplete gestures
    /// - **Multi-directional**: Supports horizontal and vertical swipes
    var dismissGestures: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                if configuration.swipeToDismiss {
                    dragOffset = value.translation
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                if abs(value.translation.width) > threshold || abs(value.translation.height) > threshold {
                    onDismiss()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
            }
    }
}

// MARK: - Shadow Application
private extension View {
    /// Applies shadow styling based on the provided shadow configuration.
    ///
    /// Conditionally applies drop shadow effects based on the shadow style,
    /// supporting both disabled (flat) and enabled (with parameters) modes.
    ///
    /// - Parameter shadowStyle: The shadow configuration to apply.
    /// - Returns: The view with appropriate shadow effects applied.
    ///
    /// ## Shadow Modes:
    /// - **Disabled**: No shadow applied (flat appearance)
    /// - **Enabled**: Drop shadow with custom radius, opacity, and offset
    ///
    /// ## Visual Impact:
    /// - Creates depth and separation from background content
    /// - Enhances visual hierarchy and toast prominence
    /// - Improves readability against complex backgrounds
    @ViewBuilder
    func applyShadow(_ shadowStyle: ShadowStyle) -> some View {
        switch shadowStyle {
        case .disabled:
            self
        case .enabled(let radius, let opacity, let offset):
            self.shadow(
                color: .black.opacity(opacity),
                radius: radius,
                x: offset.x,
                y: offset.y
            )
        }
    }
}

// MARK: - Content Layout Helpers
private extension ToastView {
    /// Leading content area that adapts based on text alignment and icon presence.
    ///
    /// Dynamically determines what should appear on the leading (left) side
    /// of the toast based on text alignment configuration and icon availability.
    ///
    /// ## Layout Logic:
    /// - **Leading Alignment + Icon**: Shows icon
    /// - **Center/Trailing Alignment**: Shows spacer for layout balance
    /// - **No Icon**: Shows spacer only for trailing alignment
    @ViewBuilder
    var leadingContent: some View {
        if configuration.textAlignment == .leading {
            icon()
        } else if shouldAddLeadingSpacer {
            Spacer()
        }
    }
    
    /// Main content area containing the primary message and optional buttons.
    ///
    /// Vertically stacks the message text and button row (if present),
    /// with alignment determined by the text alignment configuration.
    ///
    /// ## Content Structure:
    /// 1. **Message Row**: Icon (center/trailing) + Text + Icon (trailing only)
    /// 2. **Button Row**: Action buttons with appropriate spacing and alignment
    ///
    /// ## Alignment Behavior:
    /// - **Leading**: Icon on left, text flows naturally
    /// - **Center**: Icon before centered text
    /// - **Trailing**: Icon after right-aligned text
    var mainContent: some View {
        VStack(alignment: configuration.textAlignment) {
            HStack {
                if configuration.textAlignment == .center {
                    icon()
                }
                
                Text(displayMessage)
                    .font(theme.messageFont)
                    .foregroundStyle(theme.colorStyle(for: toast.category).foregroundColor)
                    .multilineTextAlignment(textAlignmentFromHorizontal(configuration.textAlignment))
                
                if configuration.textAlignment == .trailing {
                    icon()
                }
            }
            
            if !actionButtons.isEmpty {
                buttonRow
            }
        }
    }
    
    /// Trailing content area that provides layout balance when needed.
    ///
    /// Adds spacers on the trailing (right) side when necessary to maintain
    /// proper layout balance, particularly for center and leading alignments.
    @ViewBuilder
    var trailingContent: some View {
        if shouldAddTrailingSpacer {
            Spacer()
        }
    }
    
    /// Horizontal row of action buttons with proper spacing and alignment.
    ///
    /// Renders interactive buttons that allow users to take actions directly
    /// from the toast dialog without dismissing it first.
    ///
    /// ## Button Behavior:
    /// - Uses plain button style for custom theming
    /// - Applies semantic colors based on toast type
    /// - Maintains consistent font styling from theme
    /// - Supports all button roles (default, cancel, destructive)
    ///
    /// ## Layout Alignment:
    /// - **Leading**: Buttons align left with trailing spacer
    /// - **Center**: Buttons center naturally without spacers
    /// - **Trailing**: Buttons align right with leading spacer
    var buttonRow: some View {
        HStack(spacing: 8) {
            if configuration.textAlignment == .trailing {
                Spacer()
            }
            
            ForEach(Array(actionButtons.enumerated()), id: \.offset) { index, button in
                Button(action: button.action) {
                    Text(button.title)
                        .font(theme.buttonFont)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.colorStyle(for: toast.category).foregroundColor)
            }
            
            if configuration.textAlignment == .leading {
                Spacer()
            }
        }
        .padding(.top, 4)
    }
    
    /// Determines whether a leading spacer should be added for layout balance.
    ///
    /// Uses text alignment and icon presence to decide if a leading spacer
    /// is needed to maintain proper visual balance and alignment.
    ///
    /// ## Logic:
    /// - **Center Alignment + Icon**: Adds spacer to balance icon placement
    /// - **Trailing Alignment**: Always adds spacer to push content right
    /// - **Leading Alignment**: Never adds spacer (content flows naturally)
    ///
    /// - Returns: true if a leading spacer should be added, false otherwise.
    var shouldAddLeadingSpacer: Bool {
        var hasIcon = false
        if case let .custom(content, _) as DialogCustomType<AnyView, AnyView> = toast, content.iconView?() != nil {
            hasIcon = true
        }

        // Determine whether to add a leading spacer based on text alignment
        switch configuration.textAlignment {
        case .center:
            // Add a spacer if there is an icon for center alignment
            return hasIcon
        case .trailing:
            // Always add a spacer for trailing alignment
            return true
        default:
            // Do not add a spacer for leading alignment
            return false
        }
    }
    
    /// Determines whether a trailing spacer should be added for layout balance.
    ///
    /// Uses text alignment and button presence to decide if a trailing spacer
    /// is needed to maintain proper visual balance when buttons are not present.
    ///
    /// ## Logic:
    /// - **Leading/Center + No Buttons**: Adds spacer to fill remaining space
    /// - **Trailing Alignment**: Never adds spacer (content flows naturally)
    /// - **With Buttons**: No spacer needed (buttons provide trailing content)
    ///
    /// - Returns: true if a trailing spacer should be added, false otherwise.
    var shouldAddTrailingSpacer: Bool {
        let hasButtons = !actionButtons.isEmpty
        
        switch configuration.textAlignment {
        case .leading, .center:
            return !hasButtons
        default:
            return false
        }
    }
}

// MARK: - Alignment Utilities
private extension ToastView {
    /// Converts SwiftUI HorizontalAlignment to TextAlignment for text rendering.
    ///
    /// Maps the horizontal alignment configuration to the appropriate text
    /// alignment value for proper text rendering within the toast message.
    ///
    /// - Parameter horizontal: The horizontal alignment to convert.
    /// - Returns: The corresponding TextAlignment value.
    ///
    /// ## Mapping:
    /// - `.leading` → `.leading`
    /// - `.center` → `.center`
    /// - `.trailing` → `.trailing`
    /// - **Default**: `.leading` (fallback for unknown values)
    func textAlignmentFromHorizontal(_ horizontal: HorizontalAlignment) -> TextAlignment {
        switch horizontal {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
}
