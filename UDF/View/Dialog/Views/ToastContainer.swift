//===--- ToastContainer.swift ----------------------------------===//
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

/// A container view responsible for managing and displaying multiple toast dialogs.
///
/// `ToastContainer` provides the infrastructure for positioning, layering, and managing
/// multiple toast dialogs simultaneously. It handles the geometric calculations
/// needed for proper toast positioning relative to screen boundaries and safe areas,
/// while ensuring toasts don't interfere with user interaction with underlying content.
///
/// ## Features:
/// - **Multi-toast Support**: Displays multiple toasts simultaneously with proper layering
/// - **Safe Area Awareness**: Automatically adjusts positioning for device safe areas
/// - **Position Management**: Handles all toast position variants (top, bottom, center, custom)
/// - **Queue Management**: Supports both stacked and sequential toast queuing behavior
/// - **Interaction Isolation**: Prevents toasts from blocking user interaction with app content
/// - **Geometry Responsive**: Adapts toast positioning to different screen sizes and orientations
struct ToastContainer: View {
    
    // MARK: - Properties
    
    /// Queue manager responsible for maintaining toast display order and timing.
    @EnvironmentObject private var queueManager: ToastQueueManager
    
    /// Callback executed when a toast should be dismissed.
    let onDismiss: (UUID) -> Void
    
    // Storage for initial toasts that will be processed once the environment object is available
    @State private var _initialToasts: [DialogTypeProtocol]?

    // MARK: - Initialization
    
    /// Creates a new toast container with the specified parameters.
    ///
    /// - Parameters:
    ///   - initialToasts: Optional array of toast dialogs to display immediately.
    ///   - configuration: The configuration controlling toast appearance and behavior.
    ///   - onDismiss: Callback executed when a toast is dismissed.
    init(
        initialToasts: [DialogTypeProtocol] = [],
        onDismiss: @escaping (UUID) -> Void
    ) {
        self.onDismiss = onDismiss
        self._initialToasts = initialToasts.isEmpty ? nil : initialToasts
    }
    
    // MARK: - Body
    
    /// The main container view that renders all active toast dialogs.
    ///
    /// Creates a geometry-aware container that positions each toast according to
    /// its configuration while ensuring proper layering and interaction behavior.
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach([ToastPosition.top, .center, .bottom], id: \.self) { position in
                    let toastsForPosition = queueManager.visibleToasts.filter { displayInfo in
                        let config = effectiveConfiguration(for: displayInfo)
                        return config.position == position
                    }

                    if !toastsForPosition.isEmpty {
                        VStack(spacing: queueManager.configuration.stackSpacing) {
                            ForEach(position == .bottom ? toastsForPosition.reversed() : toastsForPosition, id: \.self) { displayInfo in
                                let configuration = effectiveConfiguration(for: displayInfo)
                                let toast: any DialogTypeProtocol = displayInfo.toast

                                ToastView(
                                    toast: toast,
                                    configuration: configuration,
                                    onDismiss: {
                                        queueManager.dismiss(displayInfo.id)
                                        onDismiss(displayInfo.id)
                                    }
                                )
                                .padding(.horizontal)
                                .transition(configuration.transition)
                                .id(displayInfo.id)
                                .allowsHitTesting(configuration.tapToDismiss || configuration.swipeToDismiss)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: position))
                        .offset(offset(for: position, in: geometry))
                    }
                }
            }
            .animation(.default, value: queueManager.visibleToasts)
        }
        .onAppear {
            if let initialToasts = _initialToasts {
                for toast in initialToasts {
                    queueManager.enqueue(toast)
                }
                _initialToasts = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines the effective configuration for a specific toast.
    ///
    /// Combines the container's base configuration with any toast-specific
    /// configuration overrides.
    ///
    /// - Parameter displayInfo: The toast display information.
    /// - Returns: The effective configuration to use for the toast.
    private func effectiveConfiguration(for displayInfo: ToastDisplayInfo) -> ToastConfiguration {
        // Use toast-specific configuration if available, otherwise use container config
        if let toastConfig = displayInfo.toast.toastConfiguration {
            return toastConfig
        }
        return .default
    }
    
    /// Calculates the stack offset for a toast based on its position in the stack.
    ///
    /// For stacked display mode, this determines how much vertical offset to apply
    /// for each toast in the stack.
    ///
    /// - Parameter displayInfo: The toast display information.
    /// - Returns: The vertical offset to apply for stacked positioning.
    private func stackOffset(for displayInfo: ToastDisplayInfo) -> CGFloat {
        if queueManager.configuration.displayMode == .stacked {
            return queueManager.configuration.stackOffset(for: displayInfo.stackPosition)
        }
        return 0
    }
    
    private func alignment(for position: ToastPosition) -> Alignment {
        switch position {
        case .top:
            return .top
        case .center:
            return .center
        case .bottom:
            return .bottom
        case .custom:
            return .center // Custom offset will be handled by offset modifier
        }
    }
    
    private func offset(for position: ToastPosition, in geometry: GeometryProxy) -> CGSize {
        switch position {
        case .top, .center, .bottom:
            return .zero
        case .custom(_, let offset):
            return CGSize(width: offset.x, height: offset.y)
        }
    }
}
