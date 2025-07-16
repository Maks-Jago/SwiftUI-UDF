//===--- ToastQueueConfiguration.swift ---------------------------------===//
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

/// Configuration for toast queue behavior and display management.
///
/// `ToastQueueConfiguration` controls how multiple toast dialogs are handled,
/// including display mode (sequential vs stacked), queue limits, and overflow behavior.
/// This enables sophisticated toast management for applications with frequent dialogs.
///
/// ## Usage:
/// ```swift
/// // Default configuration (sequential, limit 3)
/// let config = ToastQueueConfiguration()
/// 
/// // Stacked toasts with higher limit
/// let stackedConfig = ToastQueueConfiguration(
///     displayMode: .stacked,
///     maxStackedToasts: 5
/// )
/// 
/// // Sequential with custom spacing
/// let sequentialConfig = ToastQueueConfiguration(
///     displayMode: .sequential,
///     sequentialSpacing: 1.0
/// )
/// ```
public struct ToastQueueConfiguration: Hashable, Sendable {
    
    /// Defines how multiple toasts are displayed when queued.
    public enum DisplayMode: Equatable, Sendable {
        /// Display toasts one at a time in sequence.
        ///
        /// New toasts wait in queue until the current toast is dismissed,
        /// then the next toast appears. Provides clean, non-overlapping
        /// presentation ideal for focused attention.
        case sequential
        
        /// Display multiple toasts simultaneously in a stack.
        ///
        /// Multiple toasts appear on screen at once, positioned relative
        /// to each other. Enables quick scanning of multiple dialogs
        /// but may consume more screen space.
        case stacked
    }
    
    // MARK: - Queue Management Properties
    
    /// The display mode for handling multiple toasts.
    ///
    /// Determines whether toasts appear sequentially (one at a time) or
    /// stacked (multiple simultaneously visible).
    /// - Default: `.sequential`
    public var displayMode: DisplayMode
    
    /// Maximum number of toasts that can be stacked simultaneously.
    ///
    /// When in stacked mode, this limits how many toasts appear on screen
    /// at once. When exceeded, automatically switches to sequential mode
    /// for overflow toasts.
    /// - Default: 3
    public var maxStackedToasts: Int
    
    /// Maximum total number of toasts that can be queued.
    ///
    /// Limits the total queue size to prevent memory issues with rapid
    /// toast generation. Oldest toasts are removed when limit is exceeded.
    /// - Default: 10
    public var maxQueueSize: Int
    
    // MARK: - Timing Properties
    
    /// Delay between sequential toast presentations in seconds.
    ///
    /// Controls the gap between dismissing one toast and showing the next
    /// in sequential mode. Provides breathing room between dialogs.
    /// - Default: 0.2 seconds
    public var sequentialSpacing: TimeInterval
    
    /// Whether to show all queued toasts immediately when switching to stacked mode.
    ///
    /// When transitioning from sequential to stacked mode, determines if
    /// queued toasts should all appear at once or continue sequential timing.
    /// - Default: true
    public var showQueuedToastsImmediately: Bool
    
    // MARK: - Visual Properties
    
    /// Vertical spacing between stacked toasts in points.
    ///
    /// Controls the gap between individual toasts when displayed in stacked mode.
    /// Larger values provide more separation but consume more screen space.
    /// - Default: 8 points
    public var stackSpacing: CGFloat
    
    /// Maximum vertical offset for stacked toast positioning.
    ///
    /// Prevents stacked toasts from extending too far off-screen by limiting
    /// the total stack height. Older toasts may be hidden when exceeded.
    /// - Default: 200 points
    public var maxStackOffset: CGFloat
    
    // MARK: - Animation Properties
    
    /// Animation used for queue transitions and stacking.
    ///
    /// Controls the timing and easing for toast queue operations including
    /// appearing, disappearing, and repositioning in stacks.
    /// - Default: Spring animation with 0.3s response
    public var queueAnimation: Animation
    
    /// Whether to use staggered animations for stacked toasts.
    ///
    /// When true, stacked toasts animate in with slight delays creating
    /// a cascading effect. When false, all toasts animate simultaneously.
    /// - Default: true
    public var useStaggeredAnimations: Bool
    
    /// Delay between staggered animations in seconds.
    ///
    /// Controls the timing offset between individual toast animations
    /// when staggered animations are enabled.
    /// - Default: 0.1 seconds
    public var staggerDelay: TimeInterval
    
    // MARK: - Initializer
    
    /// Creates a new toast queue configuration with the specified parameters.
    ///
    /// All parameters have sensible defaults optimized for most use cases.
    /// Customize only the specific behavior you need to change.
    ///
    /// - Parameters:
    ///   - displayMode: How multiple toasts are displayed. Defaults to `.sequential`.
    ///   - maxStackedToasts: Maximum simultaneous stacked toasts. Defaults to 3.
    ///   - maxQueueSize: Maximum total queue size. Defaults to 10.
    ///   - sequentialSpacing: Delay between sequential toasts. Defaults to 0.2s.
    ///   - showQueuedToastsImmediately: Show queued toasts immediately in stacked mode. Defaults to true.
    ///   - stackSpacing: Vertical spacing between stacked toasts. Defaults to 8pt.
    ///   - maxStackOffset: Maximum stack height. Defaults to 200pt.
    ///   - queueAnimation: Animation for queue operations. Defaults to spring.
    ///   - useStaggeredAnimations: Enable staggered animations. Defaults to true.
    ///   - staggerDelay: Delay between staggered animations. Defaults to 0.1s.
    ///
    /// ## Example:
    /// ```swift
    /// let config = ToastQueueConfiguration(
    ///     displayMode: .stacked,
    ///     maxStackedToasts: 5,
    ///     stackSpacing: 12
    /// )
    /// ```
    public init(
        displayMode: DisplayMode = .sequential,
        maxStackedToasts: Int = 3,
        maxQueueSize: Int = 10,
        sequentialSpacing: TimeInterval = 0.2,
        showQueuedToastsImmediately: Bool = true,
        stackSpacing: CGFloat = 8,
        maxStackOffset: CGFloat = 200,
        queueAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7),
        useStaggeredAnimations: Bool = true,
        staggerDelay: TimeInterval = 0.1
    ) {
        self.displayMode = displayMode
        self.maxStackedToasts = maxStackedToasts
        self.maxQueueSize = maxQueueSize
        self.sequentialSpacing = sequentialSpacing
        self.showQueuedToastsImmediately = showQueuedToastsImmediately
        self.stackSpacing = stackSpacing
        self.maxStackOffset = maxStackOffset
        self.queueAnimation = queueAnimation
        self.useStaggeredAnimations = useStaggeredAnimations
        self.staggerDelay = staggerDelay
    }
}

// MARK: - Preset Configurations

public extension ToastQueueConfiguration {
    /// Default sequential configuration optimized for most applications.
    ///
    /// Displays toasts one at a time with brief spacing between them.
    /// Provides clean, focused dialog presentation.
    static let sequential = ToastQueueConfiguration(
        displayMode: .sequential
    )
    
    /// Stacked configuration for high-frequency dialogs.
    ///
    /// Displays multiple toasts simultaneously in a vertical stack.
    /// Ideal for applications with frequent status updates.
    static let stacked = ToastQueueConfiguration(
        displayMode: .stacked,
        maxStackedToasts: 4,
        stackSpacing: 10
    )
    
    /// Minimal configuration with reduced visual complexity.
    ///
    /// Uses sequential display with minimal spacing and simplified animations.
    /// Suitable for applications prioritizing simplicity over rich presentation.
    static let minimal = ToastQueueConfiguration(
        displayMode: .sequential,
        maxStackedToasts: 2,
        sequentialSpacing: 0.1,
        stackSpacing: 6,
        useStaggeredAnimations: false
    )
    
    /// High-capacity configuration for dialog-heavy applications.
    ///
    /// Supports larger queue sizes and more simultaneous toasts.
    /// Designed for dashboards, monitoring tools, or chat applications.
    static let highCapacity = ToastQueueConfiguration(
        displayMode: .stacked,
        maxStackedToasts: 6,
        maxQueueSize: 20,
        stackSpacing: 6,
        maxStackOffset: 300
    )
}

// MARK: - Dynamic Behavior

public extension ToastQueueConfiguration {
    /// Determines the effective display mode based on current queue state.
    ///
    /// Implements the auto-fallback behavior where stacked mode switches to
    /// sequential when the stack limit is exceeded.
    ///
    /// - Parameter currentStackCount: Number of currently displayed toasts.
    /// - Returns: The display mode to use for the next toast.
    func effectiveDisplayMode(currentStackCount: Int) -> DisplayMode {
        switch displayMode {
        case .sequential:
            return .sequential
        case .stacked:
            return currentStackCount >= maxStackedToasts ? .sequential : .stacked
        }
    }
    
    /// Calculates the vertical offset for a toast at the given stack position.
    ///
    /// Determines proper spacing and positioning for stacked toasts while
    /// respecting maximum offset limits.
    ///
    /// - Parameter stackPosition: The position in the stack (0 = top/newest).
    /// - Returns: The vertical offset in points from the base position.
    func stackOffset(for stackPosition: Int) -> CGFloat {
        let baseOffset = CGFloat(stackPosition) * stackSpacing
        return min(baseOffset, maxStackOffset)
    }
    
    /// Calculates the animation delay for staggered toast presentation.
    ///
    /// Provides progressive delays for smooth cascading animations when
    /// staggered animations are enabled.
    ///
    /// - Parameter stackPosition: The position in the stack (0 = top/newest).
    /// - Returns: The animation delay in seconds.
    func animationDelay(for stackPosition: Int) -> TimeInterval {
        guard useStaggeredAnimations else { return 0 }
        return Double(stackPosition) * staggerDelay
    }
}

//===--- ToastQueueManager.swift ---------------------------------===//

/// Manages the queue and display logic for toast dialogs.
///
/// `ToastQueueManager` handles the complex logic of queueing, displaying, and
/// managing multiple toast dialogs according to the configured behavior.
/// It implements both sequential and stacked display modes with automatic fallback.
@MainActor
public class ToastQueueManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently visible toasts with their display information.
    @Published public private(set) var visibleToasts: [ToastDisplayInfo] = []
    
    /// Toasts waiting in queue for display.
    @Published public private(set) var queuedToasts: [any DialogTypeProtocol] = []

    // MARK: - Configuration
    
    /// The configuration controlling queue behavior.
    public var configuration: ToastQueueConfiguration {
        didSet {
            applyConfigurationChanges()
        }
    }
    
    // MARK: - Private State
    
    private var dismissTasks: [UUID: Task<Void, Never>] = [:]
    private var isProcessingQueue = false
    
    // MARK: - Initializer
    
    /// Creates a new toast queue manager with the specified configuration.
    ///
    /// - Parameter configuration: The queue configuration to use.
    public init(configuration: ToastQueueConfiguration = .sequential) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Adds a new toast to the queue for display.
    ///
    /// The toast will be displayed according to the current configuration,
    /// either immediately (if space available) or queued for later display.
    ///
    /// - Parameter toast: The toast dialog to display.
    public func enqueue(_ toast: any DialogTypeProtocol) {
        let toastConfig = (toast as? DialogType)?.toastConfiguration ?? .default
        let animation = toastConfig.animation
        
        // Remove queued toasts if queue size is exceeded
        while (visibleToasts.count + queuedToasts.count + 1) > configuration.maxQueueSize && !queuedToasts.isEmpty {
            queuedToasts.removeFirst()
        }
        
        // Dismiss oldest visible toast if still over limit
        if (visibleToasts.count + queuedToasts.count + 1) > configuration.maxQueueSize {
            if let oldestVisible = visibleToasts.first {
                withAnimation(animation) {
                    dismiss(oldestVisible.id)
                }
            }
        }
        
        // Enqueue the new toast
        queuedToasts.append(toast)
        
        // Process the queue
        processQueue()
    }
    
    /// Dismisses a specific toast and updates the queue accordingly.
    ///
    /// Removes the toast from display and advances the queue if in sequential mode.
    ///
    /// - Parameter toastId: The unique identifier of the toast to dismiss.
    public func dismiss(_ toastId: UUID) {
        // Cancel auto-dismiss task
        dismissTasks[toastId]?.cancel()
        dismissTasks.removeValue(forKey: toastId)
        
        // Remove from visible toasts
        visibleToasts.removeAll { $0.id == toastId }
        
        // Update stack positions after removal
        if configuration.displayMode == .stacked {
            updateStackPositions()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(configuration.sequentialSpacing * 1_000_000_000))
                processQueue()
            }
        }
        
        // Process queue for next toast
        if configuration.displayMode == .sequential {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(configuration.sequentialSpacing * 1_000_000_000))
                processQueue()
            }
        }
    }
    
    /// Clears all toasts from both the visible list and queue.
    ///
    /// Useful for resetting the dialog state or handling app state changes.
    public func clearAll() {
        // Cancel all auto-dismiss tasks
        dismissTasks.values.forEach { $0.cancel() }
        dismissTasks.removeAll()
        
        // Clear all toasts
        visibleToasts.removeAll()
        queuedToasts.removeAll()
    }
    
    /// Returns the current queue statistics for monitoring or debugging.
    ///
    /// - Returns: Information about current queue state and capacity.
    public func queueInfo() -> QueueInfo {
        QueueInfo(
            visibleCount: visibleToasts.count,
            queuedCount: queuedToasts.count,
            totalCapacity: configuration.maxQueueSize,
            stackCapacity: configuration.maxStackedToasts,
            currentMode: configuration.effectiveDisplayMode(currentStackCount: visibleToasts.count)
        )
    }
}

// MARK: - Queue Processing
private extension ToastQueueManager {
    func processQueue() {
        guard !isProcessingQueue, !queuedToasts.isEmpty else { return }
        
        isProcessingQueue = true
        defer { isProcessingQueue = false }
        
        let effectiveMode = configuration.effectiveDisplayMode(currentStackCount: visibleToasts.count)
        
        switch effectiveMode {
        case .sequential:
            if visibleToasts.isEmpty {
                showNextToast()
            }
        case .stacked:
            while visibleToasts.count < configuration.maxStackedToasts && !queuedToasts.isEmpty {
                showNextToast()
            }
        }
    }
    
    func showNextToast() {
        guard let toast = queuedToasts.first else {
            return
        }
        queuedToasts.removeFirst()
        
        let displayInfo = ToastDisplayInfo(
            id: UUID(),
            toast: toast,
            stackPosition: visibleToasts.count,
            appearanceTime: Date()
        )
        
        withAnimation(configuration.queueAnimation.delay(configuration.animationDelay(for: displayInfo.stackPosition))) {
            visibleToasts.append(displayInfo)
        }
        
        if configuration.displayMode == .stacked {
            updateStackPositions()
        }
        
        scheduleAutoDismiss(for: displayInfo)
    }
    
    func updateStackPositions() {
        for (index, _) in visibleToasts.enumerated() {
            visibleToasts[index].stackPosition = index
        }
    }
    
    func scheduleAutoDismiss(for displayInfo: ToastDisplayInfo) {
        let duration = if case .toast(let configs) = displayInfo.toast.style {
            configs.defaultDuration
        } else {
            2.0
        }

        guard duration > 0 else { return }
        
        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                dismiss(displayInfo.id)
            }
        }
        
        dismissTasks[displayInfo.id] = task
    }
    
    func applyConfigurationChanges() {
        // Handle mode changes
        if configuration.displayMode == .stacked && configuration.showQueuedToastsImmediately {
            processQueue()
        }
        
        // Enforce new limits
        if visibleToasts.count > configuration.maxStackedToasts {
            let excess = visibleToasts.count - configuration.maxStackedToasts
            for _ in 0..<excess {
                if let oldest = visibleToasts.first {
                    dismiss(oldest.id)
                }
            }
        }
        
        // Update queue size
        if queuedToasts.count > configuration.maxQueueSize {
            let excess = queuedToasts.count - configuration.maxQueueSize
            queuedToasts.removeFirst(excess)
        }
    }
}

// MARK: - Supporting Types
/// Information about a toast currently being displayed.
public struct ToastDisplayInfo: Identifiable, Hashable {
    public let id: UUID
    public let toast: any DialogTypeProtocol
    public var stackPosition: Int
    public let appearanceTime: Date
    
    public static func == (lhs: ToastDisplayInfo, rhs: ToastDisplayInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(toast)
        hasher.combine(stackPosition)
        hasher.combine(appearanceTime)
    }
}

/// Information about the current queue state.
public struct QueueInfo {
    public let visibleCount: Int
    public let queuedCount: Int
    public let totalCapacity: Int
    public let stackCapacity: Int
    public let currentMode: ToastQueueConfiguration.DisplayMode
    
    public var isAtCapacity: Bool {
        (visibleCount + queuedCount) >= totalCapacity
    }
    
    public var isStackFull: Bool {
        visibleCount >= stackCapacity
    }
}

// MARK: - Smart Dismissal Logic
public extension ToastQueueManager {
    /// Automatically handles dismissal based on toast importance.
    /// If there are important messages, it dismisses the visible toasts.
    /// If no important messages are present, it clears all toasts.
    func handleSmartDismissal() {
        visibleToasts.forEach { dismiss($0.id) }
        
        if configuration.displayMode == .stacked {
            updateStackPositions()
        }
        
        queuedToasts = ToastImportanceEvaluator.filterImportant(from: queuedToasts)
        
        processQueue()
    }
}
