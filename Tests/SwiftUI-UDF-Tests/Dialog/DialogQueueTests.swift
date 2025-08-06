import SwiftUI
@testable import UDF
import Testing

@Suite(.serialized) struct DialogQueueTests {
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
    @Test
    @MainActor
    func QueueManager_InitialState() {
        let queueManager = ToastQueueManager()

        #expect(queueManager.visibleToasts.isEmpty)
        #expect(queueManager.queuedToasts.isEmpty)

        let info = queueManager.queueInfo()
        #expect(info.visibleCount == 0)
        #expect(info.queuedCount == 0)
        #expect(!info.isAtCapacity)
        #expect(!info.isStackFull)
    }

    @Test
    @MainActor
    func QueueManager_EnqueueSingleToast() {
        let queueManager = ToastQueueManager()
        let toast = createToastDialog("Test Toast")
        
        queueManager.enqueue(toast)
        
        // In sequential mode, toast should immediately become visible
        #expect(queueManager.visibleToasts.count == 1)
        #expect(queueManager.queuedToasts.count == 0)
        
        let info = queueManager.queueInfo()
        #expect(info.visibleCount == 1)
        #expect(info.queuedCount == 0)
    }

    // MARK: - Sequential Mode Tests
    @Test
    @MainActor
    func SequentialMode_QueuesToastsInOrder() {
        let config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Enqueue multiple toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        // In sequential mode, only first should be visible
        #expect(queueManager.visibleToasts.count == 1)
        #expect(queueManager.queuedToasts.count == 2)
        
        // Verify first toast is visible
        if let firstToast = queueManager.visibleToasts.first {
            #expect(firstToast.toast.message == "Toast 1")
        }
    }
    
    @Test
    @MainActor
    func SequentialMode_DismissAdvancesQueue() async {
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
        
        // Wait for sequential spacing and queue processing
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Second toast should now be visible
        #expect(queueManager.visibleToasts.count == 1)
        #expect(queueManager.queuedToasts.count == 1)
        
        if let visibleToast = queueManager.visibleToasts.first {
            #expect(visibleToast.toast.message == "Toast 2")
        }
    }
    
    // MARK: - Stacked Mode Tests
    @Test
    @MainActor
    func StackedMode_ShowsMultipleToasts() {
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
        #expect(queueManager.visibleToasts.count == 3)
        #expect(queueManager.queuedToasts.count == 0)
        
        // Check stack positions
        for (index, displayInfo) in queueManager.visibleToasts.enumerated() {
            #expect(displayInfo.stackPosition == index)
        }
    }
    
    @Test
    @MainActor
    func StackedMode_RespectsMaxStackLimit() {
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
        #expect(queueManager.visibleToasts.count == 2)
        #expect(queueManager.queuedToasts.count == 2)
        
        let info = queueManager.queueInfo()
        #expect(info.isStackFull)
    }
    
    @Test
    @MainActor
    func StackedMode_StackPositionsUpdate() {
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
            #expect(queueManager.visibleToasts.count == 2)
            #expect(queueManager.visibleToasts[0].stackPosition == 0)
            #expect(queueManager.visibleToasts[1].stackPosition == 1)
        }
    }
    
    // MARK: - Queue Capacity Tests
    @Test
    @MainActor
    func QueueCapacity_RemovesOldestWhenFull() {
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
        #expect(totalToasts <= config.maxQueueSize)
        
        // In sequential mode, we should have 1 visible and 2 queued
        #expect(queueManager.visibleToasts.count == 1)
        #expect(queueManager.queuedToasts.count == 2)
        
        // Oldest queued toast should have been removed
        if queueManager.queuedToasts.count >= 2 {
            #expect(queueManager.queuedToasts[0].message == "Toast 3")
            #expect(queueManager.queuedToasts[1].message == "Toast 4")
        }
    }
    
    @Test
    @MainActor
    func QueueCapacity_DismissesVisibleWhenNecessary() {
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
        #expect(queueManager.visibleToasts.count == 2)
        
        // Add another - should dismiss oldest visible
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        // Should still have 2 visible (Toast 2 and Toast 3)
        #expect(queueManager.visibleToasts.count == 2)
        #expect(queueManager.queuedToasts.count == 0)
    }
    
    // MARK: - Clear All Tests
    @Test
    @MainActor
    func ClearAll_RemovesAllToasts() {
        let config = ToastQueueConfiguration(displayMode: .stacked)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Add multiple toasts
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        #expect(queueManager.visibleToasts.count > 0)
        
        // Clear all
        queueManager.clearAll()
        
        #expect(queueManager.visibleToasts.count == 0)
        #expect(queueManager.queuedToasts.count == 0)
    }
    
    // MARK: - Configuration Change Tests
    @Test
    @MainActor
    func ConfigurationChange_FromSequentialToStacked() {
        var config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Add toasts in sequential mode
        queueManager.enqueue(createToastDialog("Toast 1"))
        queueManager.enqueue(createToastDialog("Toast 2"))
        queueManager.enqueue(createToastDialog("Toast 3"))
        
        #expect(queueManager.visibleToasts.count == 1)
        #expect(queueManager.queuedToasts.count == 2)
        
        // Change to stacked mode
        config = ToastQueueConfiguration(
            displayMode: .stacked,
            showQueuedToastsImmediately: true
        )
        queueManager.configuration = config
        
        // All queued toasts should become visible
        #expect(queueManager.visibleToasts.count == 3)
        #expect(queueManager.queuedToasts.count == 0)
    }
    
    @Test
    @MainActor
    func ConfigurationChange_ReducedStackLimit() {
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
        
        #expect(queueManager.visibleToasts.count == 4)
        
        // Reduce stack limit
        config.maxStackedToasts = 2
        queueManager.configuration = config
        
        // Should dismiss excess toasts
        #expect(queueManager.visibleToasts.count == 2)
    }
    
    // MARK: - Auto-Dismiss Tests
    @Test
    @MainActor
    func AutoDismiss_RemovesToastAfterDuration() async {
        let config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        let shortToast = createToastDialog("Short Toast", duration: 0.05)
        queueManager.enqueue(shortToast)
        
        #expect(queueManager.visibleToasts.count == 1)
        
        // Wait for auto-dismiss
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Toast should be dismissed
        #expect(queueManager.visibleToasts.count == 0)
    }
    
    @Test
    @MainActor
    func AutoDismiss_DisabledWithZeroDuration() async {
        let config = ToastQueueConfiguration(displayMode: .sequential)
        let queueManager = ToastQueueManager(configuration: config)
        
        // Create toast with zero duration (no auto-dismiss)
        let permanentToast = createToastDialog("Permanent Toast", duration: 0)
        queueManager.enqueue(permanentToast)
        
        #expect(queueManager.visibleToasts.count == 1)
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Toast should still be visible
        #expect(queueManager.visibleToasts.count == 1)
    }
    
    // MARK: - Queue Info Tests
    @Test
    @MainActor
    func QueueInfo_ProvidesAccurateStatistics() {
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
        
        #expect(info.visibleCount == 3)
        #expect(info.queuedCount == 2)
        #expect(info.totalCapacity == 5)
        #expect(info.stackCapacity == 3)
        #expect(info.isStackFull)
        #expect(info.isAtCapacity)
        #expect(info.currentMode == .sequential) // Should fallback when stack is full
    }
    
    // MARK: - Edge Cases

    @Test
    @MainActor
    func EdgeCase_EmptyQueueDismiss() {
        let queueManager = ToastQueueManager()
        
        // Dismiss non-existent toast should not crash
        queueManager.dismiss(UUID())
        
        #expect(queueManager.visibleToasts.count == 0)
        #expect(queueManager.queuedToasts.count == 0)
    }
    
    @Test 
    @MainActor
    func EdgeCase_NegativeConfiguration() {
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
        #expect(queueManager.visibleToasts.count <= 1)
    }
    
    
}
