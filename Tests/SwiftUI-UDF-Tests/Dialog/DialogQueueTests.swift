import SwiftUI
@testable import UDF
import XCTest

final class DialogQueueTests: XCTestCase {
    // MARK: - Test Helpers
    private func createToastDialog(_ message: String, duration: TimeInterval = 2.0) -> DialogType {
        let config = ToastConfiguration(defaultDuration: duration)
        return DialogType.info(message: message, style: .toast(config))
    }
    
    private func createCustomToastDialog(_ title: String, duration: TimeInterval = 2.0) -> any DialogTypeProtocol {
        let config = ToastConfiguration(defaultDuration: duration)
        let content = DialogContent(title)
        return DialogCustomType.custom(content: content, style: .toast(config))
    }
    
    // MARK: - Queue Manager Basic Tests

    @MainActor
    func test_QueueManager_InitialState() {
        let queueManager = ToastQueueManager()
        
        XCTAssertTrue(queueManager.visibleToasts.isEmpty)
        XCTAssertTrue(queueManager.queuedToasts.isEmpty)
        
        let info = queueManager.queueInfo()
        XCTAssertEqual(info.visibleCount, 0)
        XCTAssertEqual(info.queuedCount, 0)
        XCTAssertFalse(info.isAtCapacity)
        XCTAssertFalse(info.isStackFull)
    }
    
    @MainActor
    func test_QueueManager_EnqueueSingleToast() {
        let queueManager = ToastQueueManager()
        let toast = createToastDialog("Test Toast")
        
        queueManager.enqueue(toast)
        
        // In sequential mode, toast should immediately become visible
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)
        
        let info = queueManager.queueInfo()
        XCTAssertEqual(info.visibleCount, 1)
        XCTAssertEqual(info.queuedCount, 0)
    }
    
    // MARK: - Sequential Mode Tests
    
    @MainActor
    func test_SequentialMode_QueuesToastsInOrder() {
        let config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Enqueue multiple toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        // In sequential mode, only first should be visible
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        XCTAssertEqual(queueManager.queuedToasts.count, 2)
        
        // Verify first toast is visible
        if let firstToast = queueManager.visibleToasts.first {
            XCTAssertEqual(firstToast.toast.message, "Toast 1")
        }
    }
    
    @MainActor
    func test_SequentialMode_DismissAdvancesQueue() async {
        let config = ToastQueueConfiguration(
            displayMode: .sequential,
            sequentialSpacing: 0.01 // Short spacing for testing
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Enqueue multiple toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        // Dismiss first toast
        if let firstToastId = queueManager.visibleToasts.first?.id {
            queueManager.dismiss(firstToastId)
        }
        
        // Wait for sequential spacing
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        
        // Second toast should now be visible
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        XCTAssertEqual(queueManager.queuedToasts.count, 1)
        
        if let visibleToast = queueManager.visibleToasts.first {
            XCTAssertEqual(visibleToast.toast.message, "Toast 2")
        }
    }
    
    // MARK: - Stacked Mode Tests
    
    @MainActor
    func test_StackedMode_ShowsMultipleToasts() {
        let config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 3
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Enqueue multiple toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        // All should be visible in stacked mode
        XCTAssertEqual(queueManager.visibleToasts.count, 3)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)
        
        // Check stack positions
        for (index, displayInfo) in queueManager.visibleToasts.enumerated() {
            XCTAssertEqual(displayInfo.stackPosition, index)
        }
    }
    
    @MainActor
    func test_StackedMode_RespectsMaxStackLimit() {
        let config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 2
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Enqueue more toasts than stack limit
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        queueManager.enqueue(createToastDialog("Toast 4"))
        
        // Only maxStackedToasts should be visible
        XCTAssertEqual(queueManager.visibleToasts.count, 2)
        XCTAssertEqual(queueManager.queuedToasts.count, 2)
        
        let info = queueManager.queueInfo()
        XCTAssertTrue(info.isStackFull)
    }
    
    @MainActor
    func test_StackedMode_StackPositionsUpdate() {
        let config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 4
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Enqueue toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        // Dismiss middle toast
        if queueManager.visibleToasts.count >= 2 {
            let middleToastId = queueManager.visibleToasts[1].id
            queueManager.dismiss(middleToastId)
            
            // Remaining toasts should have updated positions
            XCTAssertEqual(queueManager.visibleToasts.count, 2)
            XCTAssertEqual(queueManager.visibleToasts[0].stackPosition, 0)
            XCTAssertEqual(queueManager.visibleToasts[1].stackPosition, 1)
        }
    }
    
    // MARK: - Queue Capacity Tests
    
    @MainActor
    func test_QueueCapacity_RemovesOldestWhenFull() {
        let config = ToastQueueConfiguration(
            displayMode: .sequential,
            maxQueueSize: 3
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Fill queue beyond capacity
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        queueManager.enqueue(createToastDialog("Toast 4")) // Should remove oldest queued
        
        // Total should not exceed maxQueueSize
        let totalToasts = queueManager.visibleToasts.count + queueManager.queuedToasts.count
        XCTAssertLessThanOrEqual(totalToasts, config.maxQueueSize)
        
        // In sequential mode, we should have 1 visible and 2 queued
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        XCTAssertEqual(queueManager.queuedToasts.count, 2)
        
        // Oldest queued toast should have been removed
        if queueManager.queuedToasts.count >= 2 {
            XCTAssertEqual(queueManager.queuedToasts[0].message, "Toast 3")
            XCTAssertEqual(queueManager.queuedToasts[1].message, "Toast 4")
        }
    }
    
    @MainActor
    func test_QueueCapacity_DismissesVisibleWhenNecessary() {
        let config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 2,
            maxQueueSize: 2
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Fill to capacity
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        
        // Both should be visible
        XCTAssertEqual(queueManager.visibleToasts.count, 2)
        
        // Add another - should dismiss oldest visible
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        // Should still have 2 visible (Toast 2 and Toast 3)
        XCTAssertEqual(queueManager.visibleToasts.count, 2)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)
    }
    
    // MARK: - Clear All Tests
    
    @MainActor
    func test_ClearAll_RemovesAllToasts() {
        let config = ToastQueueConfiguration(displayMode: .stacked)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Add multiple toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        XCTAssertGreaterThan(queueManager.visibleToasts.count, 0)
        
        // Clear all
        queueManager.clearAll()
        
        XCTAssertEqual(queueManager.visibleToasts.count, 0)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)
    }
    
    // MARK: - Configuration Change Tests
    
    @MainActor
    func test_ConfigurationChange_FromSequentialToStacked() {
        var config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Add toasts in sequential mode
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        XCTAssertEqual(queueManager.queuedToasts.count, 2)
        
        // Change to stacked mode
        config = ToastQueueConfiguration(
            displayMode: .stacked,
            showQueuedToastsImmediately: true
        )
        queueManager.configuration = config
        
        // All queued toasts should become visible
        XCTAssertEqual(queueManager.visibleToasts.count, 3)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)
    }
    
    @MainActor
    func test_ConfigurationChange_ReducedStackLimit() {
        var config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 4
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Add 4 toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        queueManager.enqueue(createToastDialog("Toast 4"))
        
        XCTAssertEqual(queueManager.visibleToasts.count, 4)
        
        // Reduce stack limit
        config.maxStackedToasts = 2
        queueManager.configuration = config
        
        // Should dismiss excess toasts
        XCTAssertEqual(queueManager.visibleToasts.count, 2)
    }
    
    // MARK: - Auto-Dismiss Tests
    
    @MainActor
    func test_AutoDismiss_RemovesToastAfterDuration() async {
        let config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        let shortToast = createToastDialog("Short Toast", duration: 0.05)
        queueManager.enqueue(shortToast)
        
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        
        // Wait for auto-dismiss
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Toast should be dismissed
        XCTAssertEqual(queueManager.visibleToasts.count, 0)
    }
    
    @MainActor
    func test_AutoDismiss_DisabledWithZeroDuration() async {
        let config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Create toast with zero duration (no auto-dismiss)
        let permanentToast = createToastDialog("Permanent Toast", duration: 0)
        queueManager.enqueue(permanentToast)
        
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Toast should still be visible
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
    }
    
    // MARK: - Queue Info Tests
    
    @MainActor
    func test_QueueInfo_ProvidesAccurateStatistics() {
        let config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 3,
            maxQueueSize: 5
        )
        let queueManager = ToastQueueManager(configuration: config)
        
        // Add toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        queueManager.enqueue(createToastDialog("Toast 4"))
        queueManager.enqueue(createToastDialog("Toast 5"))
        
        let info = queueManager.queueInfo()
        
        XCTAssertEqual(info.visibleCount, 3)
        XCTAssertEqual(info.queuedCount, 2)
        XCTAssertEqual(info.totalCapacity, 5)
        XCTAssertEqual(info.stackCapacity, 3)
        XCTAssertTrue(info.isStackFull)
        XCTAssertTrue(info.isAtCapacity)
        XCTAssertEqual(info.currentMode, .sequential) // Should fallback when stack is full
    }
    
    // MARK: - Edge Cases
    
    @MainActor
    func test_EdgeCase_EmptyQueueDismiss() {
        let queueManager = ToastQueueManager()
        
        // Dismiss non-existent toast should not crash
        queueManager.dismiss(UUID())
        
        XCTAssertEqual(queueManager.visibleToasts.count, 0)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)
    }
    
    @MainActor
    func test_EdgeCase_NegativeConfiguration() {
        // Configuration with edge values
        let config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 0, // Edge case
            maxQueueSize: 1
        )
        let queueManager = ToastQueueManager(configuration: config)

        // Should handle gracefully
        queueManager.enqueue(createToastDialog("Toast 1"))

        // With 0 max stack, should fallback to sequential
        XCTAssertLessThanOrEqual(queueManager.visibleToasts.count, 1)
    }

    // MARK: - Auto-Dismiss Callback Tests

    @MainActor
    func test_QueueManager_AutoDismissCallback_ExecutedOnTimerExpiry() async {
        let queueManager = ToastQueueManager()
        var callbackExecuted = false

        let config = ToastConfiguration(
            defaultDuration: 0.1, // Very short duration
            onAutoDismiss: {
                Task { @MainActor in
                    callbackExecuted = true
                }
            }
        )
        let content = DialogContent("Test Toast")
        let toast = DialogCustomType.custom(content: content, style: .toast(config))

        queueManager.enqueue(toast)

        // Wait for auto-dismiss
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

        XCTAssertTrue(callbackExecuted, "onAutoDismiss callback should be executed")
        XCTAssertEqual(queueManager.visibleToasts.count, 0, "Toast should be dismissed")
    }

    @MainActor
    func test_QueueManager_AutoDismissCallback_NotExecutedOnManualDismiss() {
        let queueManager = ToastQueueManager()
        var callbackExecuted = false

        let config = ToastConfiguration(
            defaultDuration: 10.0, // Long duration to prevent auto-dismiss
            onAutoDismiss: {
                Task { @MainActor in
                    callbackExecuted = true
                }
            }
        )
        let content = DialogContent("Test Toast")
        let toast = DialogCustomType.custom(content: content, style: .toast(config))

        queueManager.enqueue(toast)

        // Manually dismiss
        if let toastId = queueManager.visibleToasts.first?.id {
            queueManager.dismiss(toastId)
        }

        XCTAssertFalse(callbackExecuted, "onAutoDismiss callback should NOT be executed on manual dismiss")
        XCTAssertEqual(queueManager.visibleToasts.count, 0, "Toast should be dismissed")
    }

    @MainActor
    func test_QueueManager_AutoDismissCallback_SequentialMode() async {
        let config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)

        var callback1Executed = false
        var callback2Executed = false

        let toast1Config = ToastConfiguration(
            defaultDuration: 0.1,
            onAutoDismiss: {
                Task { @MainActor in
                    callback1Executed = true
                }
            }
        )
        let toast2Config = ToastConfiguration(
            defaultDuration: 0.1,
            onAutoDismiss: {
                Task { @MainActor in
                    callback2Executed = true
                }
            }
        )

        let toast1 = DialogCustomType.custom(content: DialogContent("Toast 1"), style: .toast(toast1Config))
        let toast2 = DialogCustomType.custom(content: DialogContent("Toast 2"), style: .toast(toast2Config))

        queueManager.enqueue(toast1)
        queueManager.enqueue(toast2)

        // In sequential mode, only first toast should be visible initially
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
        XCTAssertEqual(queueManager.queuedToasts.count, 1)

        // Wait for both toasts to auto-dismiss
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        XCTAssertTrue(callback1Executed, "First toast callback should execute")
        XCTAssertTrue(callback2Executed, "Second toast callback should execute after first is dismissed")
        XCTAssertEqual(queueManager.visibleToasts.count, 0)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)
    }

    @MainActor
    func test_QueueManager_AutoDismissCallback_StackedMode() async {
        let config = ToastQueueConfiguration(
            displayMode: .stacked,
            maxStackedToasts: 2
        )
        let queueManager = ToastQueueManager(configuration: config)

        var callback1Executed = false
        var callback2Executed = false

        let toast1Config = ToastConfiguration(
            defaultDuration: 0.1,
            onAutoDismiss: {
                Task { @MainActor in
                    callback1Executed = true
                }
            }
        )
        let toast2Config = ToastConfiguration(
            defaultDuration: 0.1,
            onAutoDismiss: {
                Task { @MainActor in
                    callback2Executed = true
                }
            }
        )

        let toast1 = DialogCustomType.custom(content: DialogContent("Toast 1"), style: .toast(toast1Config))
        let toast2 = DialogCustomType.custom(content: DialogContent("Toast 2"), style: .toast(toast2Config))

        queueManager.enqueue(toast1)
        queueManager.enqueue(toast2)

        // In stacked mode, both toasts should be visible
        XCTAssertEqual(queueManager.visibleToasts.count, 2)
        XCTAssertEqual(queueManager.queuedToasts.count, 0)

        // Wait for both toasts to auto-dismiss
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        XCTAssertTrue(callback1Executed, "First toast callback should execute")
        XCTAssertTrue(callback2Executed, "Second toast callback should execute")
        XCTAssertEqual(queueManager.visibleToasts.count, 0)
    }

    @MainActor
    func test_QueueManager_AutoDismissCallback_NoCallbackForNonToastStyle() async {
        let queueManager = ToastQueueManager()
        var callbackExecuted = false

        // Create a regular DialogType (not toast style)
        let dialog = DialogType.info(message: "Regular dialog", style: .alert)

        queueManager.enqueue(dialog)

        // Wait briefly
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // No callback should be executed for non-toast dialogs
        XCTAssertFalse(callbackExecuted)
    }


}
