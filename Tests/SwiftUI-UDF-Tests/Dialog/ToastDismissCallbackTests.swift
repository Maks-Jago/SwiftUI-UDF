import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@Suite(.serialized) struct ToastDismissCallbackTests {

    private class CallbackTracker: @unchecked Sendable {
        var executed = false
    }

    // MARK: - ToastConfiguration Tests

    @Test func test_ToastConfiguration_DefaultOnAutoDismiss_IsNil() {
        let config = ToastConfiguration()
        #expect(config.onAutoDismiss == nil)
    }

    @Test func test_ToastConfiguration_WithOnAutoDismiss_StoresCallback() {
        let tracker = CallbackTracker()
        let config = ToastConfiguration(onAutoDismiss: { tracker.executed = true })

        #expect(config.onAutoDismiss != nil)

        // Test callback execution
        config.onAutoDismiss?()
        #expect(tracker.executed)
    }

    @Test func test_ToastConfiguration_Equatable_WithCallbacks() {
        let config1 = ToastConfiguration(onAutoDismiss: { })
        let config2 = ToastConfiguration(onAutoDismiss: { })
        let config3 = ToastConfiguration(onAutoDismiss: nil)
        let config4 = ToastConfiguration()

        // Configurations with callbacks should be considered equal if other properties match
        // (we only check if callback is nil or not, not the actual callback)
        #expect(config1 == config2)
        #expect(config3 == config4)
        #expect(config1 != config3)
    }

    @Test func test_ToastConfiguration_Hashable_WithCallbacks() {
        let config1 = ToastConfiguration(onAutoDismiss: { })
        let config2 = ToastConfiguration(onAutoDismiss: nil)

        // Should be able to hash configurations with callbacks
        let set: Set<ToastConfiguration> = [config1, config2]
        #expect(set.count == 2)
    }

    // MARK: - DialogRegistration Tests

    @MainActor
    @Test func test_DialogRegistry_RegisterToast_WithOnAutoDismiss() {
        let testID = "test-toast-callback"
        let tracker = CallbackTracker()

        // Register toast with callback
        DialogRegistry.registerToast(id: testID) {
            DialogContent("Test Toast with Callback")
        } configuration: {
            ToastConfiguration(defaultDuration: 0.1)
        } onAutoDismiss: {
            tracker.executed = true
        }

        // Retrieve the registered toast
        let retrievedDialog = _DialogRegistry.get(id: testID)
        #expect(retrievedDialog != nil)

        // Verify it has the callback in configuration
        if let customType = retrievedDialog as? DialogCustomType<EmptyView, EmptyView>,
           case .custom(_, let style) = customType,
           case .toast(let config) = style {
            #expect(config.onAutoDismiss != nil)

            // Test callback execution
            config.onAutoDismiss?()
            #expect(tracker.executed)
        } else {
            #expect(Bool(false), "Retrieved dialog should be DialogCustomType with toast style")
        }

        // Clean up
        Dialog.unregister(id: testID)
    }

    @MainActor
    @Test func test_DialogRegistry_RegisterToast_WithoutOnAutoDismiss() {
        let testID = "test-toast-no-callback"

        // Register toast without callback
        DialogRegistry.registerToast(id: testID) {
            DialogContent("Test Toast without Callback")
        }

        // Retrieve and verify no callback
        let retrievedDialog = _DialogRegistry.get(id: testID)
        if let customType = retrievedDialog as? DialogCustomType<EmptyView, EmptyView>,
           case .custom(_, let style) = customType,
           case .toast(let config) = style {
            #expect(config.onAutoDismiss == nil)
        } else {
            #expect(Bool(false), "Retrieved dialog should be DialogCustomType with toast style")
        }

        // Clean up
        Dialog.unregister(id: testID)
    }

    // MARK: - ToastQueueManager Tests

    @MainActor
    @Test func test_ToastQueueManager_ExecutesCallbackOnAutoDismiss() async {
        let queueManager = ToastQueueManager()
        let tracker = CallbackTracker()

        let config = ToastConfiguration(
            defaultDuration: 0.1,
            onAutoDismiss: { tracker.executed = true }
        )
        
        let toast = Toast(config: config) {
            DialogMessage("Test Toast")
        }

        queueManager.enqueue(toast)

        // Verify toast is visible
        #expect(queueManager.visibleToasts.count == 1)

        // Wait for auto-dismiss
        await sleep(for: 0.5)

        // Verify callback was executed
        #expect(tracker.executed)
    }

    @MainActor
    @Test func test_ToastQueueManager_ManualDismiss_DoesNotExecuteCallback() {
        let queueManager = ToastQueueManager()
        let tracker = CallbackTracker()

        let config = ToastConfiguration(
            defaultDuration: 10.0, // Long duration
            onAutoDismiss: { tracker.executed = true }
        )
        let toast = Toast(config: config) {
            DialogMessage("Test Toast")
        }

        queueManager.enqueue(toast)

        // Get the toast ID for manual dismissal
        let toastId = queueManager.visibleToasts.first?.id
        #expect(toastId != nil)

        // Manually dismiss the toast
        queueManager.dismiss(toastId!)

        // Callback should NOT be executed for manual dismissal
        #expect(!tracker.executed)

        // Toast should be removed
        #expect(queueManager.visibleToasts.count == 0)
    }

    @MainActor
    @Test func test_ToastQueueManager_NoCallbackForZeroDuration() async {
        let queueManager = ToastQueueManager()
        let tracker = CallbackTracker()

        let config = ToastConfiguration(
            defaultDuration: 0, // No auto-dismiss
            onAutoDismiss: { tracker.executed = true }
        )
        let toast = Toast(config: config) {
            DialogMessage("Test Toast")
        }

        queueManager.enqueue(toast)

        // Wait to ensure no auto-dismiss happens
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify callback was NOT executed (no auto-dismiss)
        #expect(!tracker.executed)

        // Toast should still be visible
        #expect(queueManager.visibleToasts.count == 1)
    }
}
