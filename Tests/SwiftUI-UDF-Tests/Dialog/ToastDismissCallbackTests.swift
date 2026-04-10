import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@Suite(.serialized) struct ToastDismissCallbackTests {


    // MARK: - ToastConfiguration Tests

    @Test func test_ToastConfiguration_DefaultOnAutoDismiss_IsNil() {
        let config = ToastConfiguration()
        #expect(config.onAutoDismiss == nil)
    }

    @Test func test_ToastConfiguration_WithOnAutoDismiss_StoresCallback() async {
        await confirmation("callback fired") { confirm in
            let config = ToastConfiguration(onAutoDismiss: { confirm() })

            #expect(config.onAutoDismiss != nil)

            // Test callback execution
            config.onAutoDismiss?()
        }
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

    @Test func test_DialogRegistry_RegisterToast_WithOnAutoDismiss() async {
        let testID = "test-toast-callback"

        await confirmation("callback fired") { confirm in
            // Register toast with callback
            DialogRegistry.registerToast(id: testID) {
                DialogContent("Test Toast with Callback")
            } configuration: {
                ToastConfiguration(defaultDuration: 0.1)
            } onAutoDismiss: {
                confirm()
            }

            // Retrieve the registered toast
            let retrievedDialog = DialogRegistry.get(id: testID)
            #expect(retrievedDialog != nil)

            // Verify it has the callback in configuration
            if let customType = retrievedDialog as? DialogCustomType<EmptyView, EmptyView>,
               case .custom(_, let style) = customType,
               case .toast(let config) = style {
                #expect(config.onAutoDismiss != nil)

                // Test callback execution
                config.onAutoDismiss?()
            } else {
                #expect(Bool(false), "Retrieved dialog should be DialogCustomType with toast style")
            }
        }

        // Clean up
        DialogRegistry.unregister(id: testID)
    }

    @Test func test_DialogRegistry_RegisterToast_WithoutOnAutoDismiss() {
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
            #expect(config.onAutoDismiss == nil)
        } else {
            #expect(Bool(false), "Retrieved dialog should be DialogCustomType with toast style")
        }

        // Clean up
        DialogRegistry.unregister(id: testID)
    }

    // MARK: - ToastQueueManager Tests

    @MainActor
    @Test func test_ToastQueueManager_ExecutesCallbackOnAutoDismiss() async {
        let queueManager = ToastQueueManager()

        await confirmation("callback fired") { confirm in
            let config = ToastConfiguration(
                defaultDuration: 0.1,
                onAutoDismiss: { confirm() }
            )
            let content = DialogContent("Test Toast")
            let toast = DialogCustomType.custom(content: content, style: .toast(config))

            queueManager.enqueue(toast)

            // Verify toast is visible
            #expect(queueManager.visibleToasts.count == 1)

            // Wait for auto-dismiss
            await sleep(for: 0.5)
        }
    }

    @MainActor
    @Test func test_ToastQueueManager_ManualDismiss_DoesNotExecuteCallback() async {
        let queueManager = ToastQueueManager()

        await confirmation("callback fired", expectedCount: 0) { confirm in
            let config = ToastConfiguration(
                defaultDuration: 10.0, // Long duration
                onAutoDismiss: { confirm() }
            )
            let content = DialogContent("Test Toast")
            let toast = DialogCustomType.custom(content: content, style: .toast(config))

            queueManager.enqueue(toast)

            // Get the toast ID for manual dismissal
            let toastId = queueManager.visibleToasts.first?.id
            #expect(toastId != nil)

            // Manually dismiss the toast
            queueManager.dismiss(toastId!)

            // Wait a bit to ensure it doesn't fire
            await sleep(for: 0.2)
        }

        // Toast should be removed
        #expect(queueManager.visibleToasts.count == 0)
    }

    @MainActor
    @Test func test_ToastQueueManager_NoCallbackForZeroDuration() async {
        let queueManager = ToastQueueManager()

        await confirmation("callback fired", expectedCount: 0) { confirm in
            let config = ToastConfiguration(
                defaultDuration: 0, // No auto-dismiss
                onAutoDismiss: { confirm() }
            )
            let content = DialogContent("Persistent Toast")
            let toast = DialogCustomType.custom(content: content, style: .toast(config))

            queueManager.enqueue(toast)

            // Wait to ensure no auto-dismiss happens
            await sleep(for: 0.1)
        }

        // Toast should still be visible
        #expect(queueManager.visibleToasts.count == 1)
    }
}
