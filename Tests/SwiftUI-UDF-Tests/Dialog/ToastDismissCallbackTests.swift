import SwiftUI
@testable import UDF
import XCTest

final class ToastDismissCallbackTests: XCTestCase {

    private class CallbackTracker: @unchecked Sendable {
        var executed = false
    }

    // MARK: - ToastConfiguration Tests

    func test_ToastConfiguration_DefaultOnAutoDismiss_IsNil() {
        let config = ToastConfiguration()
        XCTAssertNil(config.onAutoDismiss)
    }

    func test_ToastConfiguration_WithOnAutoDismiss_StoresCallback() {
        let tracker = CallbackTracker()
        let config = ToastConfiguration(onAutoDismiss: { tracker.executed = true })

        XCTAssertNotNil(config.onAutoDismiss)

        // Test callback execution
        config.onAutoDismiss?()
        XCTAssertTrue(tracker.executed)
    }

    func test_ToastConfiguration_Equatable_WithCallbacks() {
        let config1 = ToastConfiguration(onAutoDismiss: { })
        let config2 = ToastConfiguration(onAutoDismiss: { })
        let config3 = ToastConfiguration(onAutoDismiss: nil)
        let config4 = ToastConfiguration()

        // Configurations with callbacks should be considered equal if other properties match
        // (we only check if callback is nil or not, not the actual callback)
        XCTAssertEqual(config1, config2)
        XCTAssertEqual(config3, config4)
        XCTAssertNotEqual(config1, config3)
    }

    func test_ToastConfiguration_Hashable_WithCallbacks() {
        let config1 = ToastConfiguration(onAutoDismiss: { })
        let config2 = ToastConfiguration(onAutoDismiss: nil)

        // Should be able to hash configurations with callbacks
        let set: Set<ToastConfiguration> = [config1, config2]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - DialogRegistration Tests

    func test_DialogRegistry_RegisterToast_WithOnAutoDismiss() {
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
        let retrievedDialog = DialogRegistry.get(id: testID)
        XCTAssertNotNil(retrievedDialog)

        // Verify it has the callback in configuration
        if let customType = retrievedDialog as? DialogCustomType<EmptyView, EmptyView>,
           case .custom(_, let style) = customType,
           case .toast(let config) = style {
            XCTAssertNotNil(config.onAutoDismiss)

            // Test callback execution
            config.onAutoDismiss?()
            XCTAssertTrue(tracker.executed)
        } else {
            XCTFail("Retrieved dialog should be DialogCustomType with toast style")
        }

        // Clean up
        DialogRegistry.unregister(id: testID)
    }

    func test_DialogRegistry_RegisterToast_WithoutOnAutoDismiss() {
        let testID = "test-toast-no-callback"

        // Register toast without callback
        DialogRegistry.registerToast(id: testID) {
            DialogContent("Test Toast without Callback")
        }

        // Retrieve and verify no callback
        let retrievedDialog = DialogRegistry.get(id: testID)
        if let customType = retrievedDialog as? DialogCustomType<EmptyView, EmptyView>,
           case .custom(_, let style) = customType,
           case .toast(let config) = style {
            XCTAssertNil(config.onAutoDismiss)
        } else {
            XCTFail("Retrieved dialog should be DialogCustomType with toast style")
        }

        // Clean up
        DialogRegistry.unregister(id: testID)
    }

    // MARK: - ToastQueueManager Tests

    @MainActor
    func test_ToastQueueManager_ExecutesCallbackOnAutoDismiss() async {
        let queueManager = ToastQueueManager()
        let tracker = CallbackTracker()

        let config = ToastConfiguration(
            defaultDuration: 0.1,
            onAutoDismiss: { tracker.executed = true }
        )
        let content = DialogContent("Test Toast")
        let toast = DialogCustomType.custom(content: content, style: .toast(config))

        queueManager.enqueue(toast)

        // Verify toast is visible
        XCTAssertEqual(queueManager.visibleToasts.count, 1)

        // Wait for auto-dismiss
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Verify callback was executed
        XCTAssertTrue(tracker.executed)
    }

    @MainActor
    func test_ToastQueueManager_ManualDismiss_DoesNotExecuteCallback() {
        let queueManager = ToastQueueManager()
        let tracker = CallbackTracker()

        let config = ToastConfiguration(
            defaultDuration: 10.0, // Long duration
            onAutoDismiss: { tracker.executed = true }
        )
        let content = DialogContent("Test Toast")
        let toast = DialogCustomType.custom(content: content, style: .toast(config))

        queueManager.enqueue(toast)

        // Get the toast ID for manual dismissal
        let toastId = queueManager.visibleToasts.first?.id
        XCTAssertNotNil(toastId)

        // Manually dismiss the toast
        queueManager.dismiss(toastId!)

        // Callback should NOT be executed for manual dismissal
        XCTAssertFalse(tracker.executed)

        // Toast should be removed
        XCTAssertEqual(queueManager.visibleToasts.count, 0)
    }

    @MainActor
    func test_ToastQueueManager_NoCallbackForZeroDuration() async {
        let queueManager = ToastQueueManager()
        let tracker = CallbackTracker()

        let config = ToastConfiguration(
            defaultDuration: 0, // No auto-dismiss
            onAutoDismiss: { tracker.executed = true }
        )
        let content = DialogContent("Persistent Toast")
        let toast = DialogCustomType.custom(content: content, style: .toast(config))

        queueManager.enqueue(toast)

        // Wait to ensure no auto-dismiss happens
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify callback was NOT executed (no auto-dismiss)
        XCTAssertFalse(tracker.executed)

        // Toast should still be visible
        XCTAssertEqual(queueManager.visibleToasts.count, 1)
    }
}
