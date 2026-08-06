
import Foundation

//===--- Actions.swift --------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import class AppTrackingTransparency.ATTrackingManager
import enum CoreLocation.CLAccuracyAuthorization
import enum CoreLocation.CLAuthorizationStatus
import class CoreLocation.CLLocation
import SwiftUI

#if canImport(UIKit)
    import UIKit.UIApplication

    public typealias PlatformApplication = UIApplication
    public typealias PlatformLaunchOptions = [UIApplication.LaunchOptionsKey: Any]?
#else
    import AppKit.NSApplication

    public typealias PlatformApplication = NSApplication
    public typealias PlatformLaunchOptions = Notification
#endif

public enum Actions {
    /// `UpdateFormField` is an action used to update a specific field in a form within the UDF architecture.
    /// It captures the key path of the property to be updated along with its new value, and provides a way to
    /// modify the corresponding property in the form.
    ///
    /// This action ensures that form updates are handled in a controlled and type-safe manner.
    public struct UpdateFormField<F: Form>: Action, @unchecked Sendable {
        /// Compares two `UpdateFormField` actions to check if they are equal.
        /// - Parameters:
        ///   - lhs: The left-hand side `UpdateFormField` to compare.
        ///   - rhs: The right-hand side `UpdateFormField` to compare.
        /// - Returns: A Boolean value indicating whether the two actions are equal.
        public static func == (lhs: Actions.UpdateFormField<F>, rhs: Actions.UpdateFormField<F>) -> Bool {
            areEqual(lhs.value, rhs.value) && lhs.keyPath.hashValue == rhs.keyPath.hashValue
        }

        /// The new value to be assigned to the form field.
        public var value: any Equatable

        /// The key path of the property in the form to be updated.
        public var keyPath: PartialKeyPath<F>

        /// A closure that performs the update on the form.
        var assignToForm: (_ form: inout F) -> Void

        /// Initializes a new `UpdateFormField` action.
        ///
        /// - Parameters:
        ///   - keyPath: The key path of the property in the form to be updated.
        ///   - value: The new value to assign to the specified property.
        public init<V: Equatable>(keyPath: WritableKeyPath<F, V>, value: V) {
            self.keyPath = keyPath
            self.value = value
            self.assignToForm = { form in
                form[keyPath: keyPath] = value
            }
        }
    }
    
    /// `UpdateAlertStatus` is an action used to update the status of an alert within the UDF architecture.
    /// It contains the alert's status and an identifier, enabling the management of alerts based on their unique IDs.
    @available(*, deprecated, message: "Will be removed in future updates. Use UpdateDialogStatus instead.")
    public struct UpdateAlertStatus: Action {
        /// The status of the alert to be updated.
        public var status: AlertBuilder.AlertStatus
        
        /// A unique identifier for the alert.
        public var id: AnyHashable
        
        /// Initializes a new `UpdateAlertStatus` action.
        ///
        /// - Parameters:
        ///   - status: The new status of the alert.
        ///   - id: The unique identifier for the alert.
        public init(status: AlertBuilder.AlertStatus, id: some Hashable) {
            self.status = status
            self.id = id
        }
        
        /// Initializes a new `UpdateAlertStatus` action with a specific alert style.
        ///
        /// - Parameters:
        ///   - style: The style of the alert to be used for creating the alert status.
        ///   - id: The unique identifier for the alert.
        public init(style: AlertBuilder.AlertStyle, id: some Hashable) {
            self.status = .init(style: style)
            self.id = id
        }
    }

    /// `UpdateDialogStatus` is an action used to update the state of a dialog within the UDF architecture.
    /// It contains the dialog's state and an identifier, enabling the management of dialogs based on their unique IDs.
    ///
    /// This is a direct migration from `UpdateAlertStatus` with the same functionality but updated to work
    /// with the new Dialog System.
    ///
    /// ## Usage:
    /// ```swift
    /// // Update with a specific dialog state
    /// let action = UpdateDialogStatus(
    ///     state: .init(error: "Something went wrong"),
    ///     id: "errorDialog"
    /// )
    /// 
    /// // Update with a dialog type
    /// let action = UpdateDialogStatus(
    ///     dialog: .success("Operation completed"),
    ///     id: "successdialog"
    /// )
    /// 
    /// // Update with custom content
    /// let action = UpdateDialogStatus(
    ///     content: DialogContent("Delete Item", message: "This cannot be undone") {
    ///         DialogButton.destructive("Delete") { performDelete() }
    ///         DialogButton.cancel("Cancel")
    ///     },
    ///     id: "deleteConfirmation"
    /// )
    /// ```
    public struct UpdateDialogStatus: Action {
        /// The state of the dialog to be updated.
        public var status: DialogStatus
        
        /// A unique identifier for the dialog.
        public var id: AnyHashable
        
        // MARK: - Initializers
        
        /// Initializes a new `UpdateDialogStatus` action with a specific dialog state.
        ///
        /// - Parameters:
        ///   - state: The new state of the dialog.
        ///   - id: The unique identifier for the dialog.
        public init(status: DialogStatus, id: some Hashable) {
            self.status = status
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action with a specific dialog type.
        ///
        /// - Parameters:
        ///   - dialog: The dialog type to be used for creating the dialog state.
        ///   - id: The unique identifier for the dialog.
        public init(dialog: DialogType, id: some Hashable) {
            self.status = .init(dialog: dialog)
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action with custom dialog content.
        ///
        /// - Parameters:
        ///   - content: The custom content for the dialog.
        ///   - id: The unique identifier for the dialog.
        ///   - style: The dialog style (defaults to .alert).
        public init<Icon: View, Content: View>(content: DialogContent<Icon, Content>, id: some Hashable, style: DialogStyle = .alert) {
            self.status = .init(dialog: DialogCustomType.custom(content: content, style: style))
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action using a type-safe DialogProtocol instance.
        ///
        /// Use this initializer when you have a pre-built dialog conforming to `DialogProtocol`
        /// (e.g., `AlertDialog`, `Toast`, `ConfirmationDialog`).
        ///
        /// - Parameters:
        ///   - dialog: A `DialogProtocol` conforming value.
        ///   - id: The unique identifier for the dialog.
        ///
        /// ## Example:
        /// ```swift
        /// let alert = AlertDialog {
        ///     DialogTitle("Error")
        ///     DialogMessage("Something went wrong.")
        ///     DialogButton(title: "OK") {}
        /// }
        /// store.dispatch(Actions.UpdateDialogStatus(dialog: alert, id: "errorDialog"))
        /// ```
        public init(dialog: any DialogProtocol, id: some Hashable) {
            self.status = .init(dialog: dialog as any DialogTypeProtocol)
            self.id = AnyHashable(id)
        }
        
        // MARK: - Convenience Initializers
        
        /// Initializes a new `UpdateDialogStatus` action with a success message.
        ///
        /// - Parameters:
        ///   - success: The success message to display.
        ///   - id: The unique identifier for the dialog.
        ///   - style: The dialog style (defaults to .alert).
        public init(success: String, id: some Hashable, style: DialogStyle = .alert) {
            self.status = .init(dialog: DialogType.success(message: success, style: style))
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action with an error message.
        ///
        /// - Parameters:
        ///   - error: The error message to display.
        ///   - id: The unique identifier for the dialog.
        ///   - style: The dialog style (defaults to .alert).
        public init(error: String, id: some Hashable, style: DialogStyle = .alert) {
            self.status = .init(dialog: DialogType.error(message: error, style: style))
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action with a warning message.
        ///
        /// - Parameters:
        ///   - warning: The warning message to display.
        ///   - id: The unique identifier for the dialog.
        ///   - style: The dialog style (defaults to .alert).
        public init(warning: String, id: some Hashable, style: DialogStyle = .alert) {
            self.status = .init(dialog: DialogType.warning(message: warning, style: style))
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action with an info message.
        ///
        /// - Parameters:
        ///   - info: The info message to display.
        ///   - id: The unique identifier for the dialog.
        ///   - style: The dialog style (defaults to .alert).
        public init(info: String, id: some Hashable, style: DialogStyle = .alert) {
            self.status = .init(dialog: DialogType.info(message: info, style: style))
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action to dismiss a dialog.
        ///
        /// - Parameter id: The unique identifier for the dialog to dismiss.
        public init(dismissing id: some Hashable) {
            self.status = .dismissed
            self.id = AnyHashable(id)
        }
        
        /// Initializes a new `UpdateDialogStatus` action using a registered dialog.
        ///
        /// - Parameters:
        ///   - registrationId: The identifier of the registered dialog.
        ///   - id: The unique identifier for this dialog instance.
        public init(registrationId: some Hashable, id: some Hashable) {
            self.status = .init(id: registrationId)
            self.id = AnyHashable(id)
        }
    }

    /// `ResetForm` is an action used to reset a form to its initial state within the UDF architecture.
    /// This action is useful when a form needs to be cleared or reverted to its default values.
    public struct ResetForm<F: Form>: Action {
        /// Initializes a new `ResetForm` action.
        ///
        /// This initializer does not take any parameters, as it simply triggers a reset for the form.
        public init() {}
    }

    /// `Error` is an action that represents an error occurrence within the UDF architecture.
    /// It conforms to both `Action` and `LocalizedError`, providing error information alongside an identifier, a code, and additional
    /// metadata.
    public struct Error: Action, LocalizedError, @unchecked Sendable {
        /// Compares two `Error` instances for equality.
        ///
        /// - Parameters:
        ///   - lhs: The left-hand side `Error` instance.
        ///   - rhs: The right-hand side `Error` instance.
        /// - Returns: A Boolean value indicating whether the two `Error` instances are equal.
        public static func == (lhs: Actions.Error, rhs: Actions.Error) -> Bool {
            lhs.error == rhs.error && lhs.id == rhs.id
        }

        /// The error message as a string.
        public var error: String?

        /// A unique identifier for the error.
        public var id: AnyHashable

        /// An integer representing the error code.
        public var code: Int

        /// Additional metadata related to the error.
        public var meta: [String: Any]?

        /// Initializes a new `Error` action.
        ///
        /// - Parameters:
        ///   - error: A string containing the error message. If the message is empty, it defaults to `nil`.
        ///   - id: A unique identifier for the error.
        ///   - code: An optional integer representing the error code. Defaults to the hash value of the error string or -1001 if not
        /// provided.
        ///   - meta: An optional dictionary containing additional metadata for the error.
        public init(error: String? = nil, id: some Hashable, code: Int? = nil, meta: [String: Any]? = nil) {
            self.error = error?.isEmpty == true ? nil : error
            self.id = AnyHashable(id)
            self.meta = meta
            self.code = if let code {
                code
            } else {
                error?.hashValue ?? -1001
            }
        }

        /// A localized description of the error.
        public var errorDescription: String? { error }
    }

    /// `Message` is an action that represents a message occurrence within the UDF architecture.
    /// It provides a message string alongside a unique identifier.
    public struct Message: Action {
        /// The message content as an optional string.
        public var message: String?

        /// A unique identifier for the message.
        public var id: AnyHashable

        /// Initializes a new `Message` action.
        ///
        /// - Parameters:
        ///   - message: A string containing the message content. If the message is empty, it defaults to `nil`.
        ///   - id: A unique identifier for the message.
        public init(message: String? = nil, id: some Hashable) {
            self.message = message?.isEmpty == true ? nil : message
            self.id = AnyHashable(id)
        }
    }

    /// `LoadPage` is an action that triggers the loading of a specific page within a paginated data structure.
    public struct LoadPage: Action {
        /// A unique identifier for the page.
        public var id: AnyHashable

        /// The page number to load.
        public var pageNumber: Int

        /// Initializes a new `LoadPage` action.
        ///
        /// - Parameters:
        ///   - pageNumber: The number of the page to load. Defaults to `1`.
        ///   - id: A unique identifier for the page.
        public init(pageNumber: Int = 1, id: some Hashable) {
            self.pageNumber = pageNumber
            self.id = AnyHashable(id)
        }
    }

    /// `SetPaginationItems` is an action that sets paginated items within a specific context.
    public struct SetPaginationItems<I: Equatable & Sendable>: Action {
        /// A unique identifier for the pagination context.
        public var id: AnyHashable

        /// An array of items to set for the pagination.
        public var items: [I]

        /// Initializes a new `SetPaginationItems` action.
        ///
        /// - Parameters:
        ///   - items: An array of items to set.
        ///   - id: A unique identifier for the pagination context.
        public init(items: [I], id: some Hashable) {
            self.items = items
            self.id = AnyHashable(id)
        }
    }

    /// `DidCancelEffect` is an action that indicates the cancellation of an effect within the UDF architecture.
    public struct DidCancelEffect: Action {
        /// The unique identifier for the effect that was cancelled.
        public var cancellation: AnyHashable

        /// Initializes a new `DidCancelEffect` action.
        ///
        /// - Parameter cancellation: The identifier of the effect that was cancelled.
        public init(by cancellation: some Hashable) {
            self.cancellation = AnyHashable(cancellation)
        }
    }

    /// `ApplicationDidReceiveMemoryWarning` is an action that signals the application has received a memory warning.
    public struct ApplicationDidReceiveMemoryWarning: Action {
        /// Initializes a new `ApplicationDidReceiveMemoryWarning` action.
        public init() {}
    }

    /// `ApplicationDidBecomeActive` is an action that signals the application has become active.
    public struct ApplicationDidBecomeActive: Action {
        /// Initializes a new `ApplicationDidBecomeActive` action.
        public init() {}
    }

    /// `ApplicationDidLaunchWithOptions` is an action that indicates the application has launched with specific options.
    public struct ApplicationDidLaunchWithOptions: Action, @unchecked Sendable {
        /// Checks the equality of two `ApplicationDidLaunchWithOptions` actions based on the `application` property.
        public static func == (lhs: ApplicationDidLaunchWithOptions, rhs: ApplicationDidLaunchWithOptions) -> Bool {
            lhs.application == rhs.application
        }

        /// The application instance that launched.
        public let application: PlatformApplication

        /// The launch options provided at the time of launch.
        public let launchOptions: PlatformLaunchOptions

        #if canImport(UIKit)
            /// Initializes a new `ApplicationDidLaunchWithOptions` action for UIKit platforms.
            ///
            /// - Parameters:
            ///   - application: The application instance that launched.
            ///   - launchOptions: The options used during launch. Defaults to `nil`.
            public init(application: PlatformApplication, launchOptions: PlatformLaunchOptions = nil) {
                self.application = application
                self.launchOptions = launchOptions
            }
        #else
            /// Initializes a new `ApplicationDidLaunchWithOptions` action for non-UIKit platforms.
            ///
            /// - Parameters:
            ///   - application: The application instance that launched.
            ///   - launchOptions: The options used during launch.
            public init(application: PlatformApplication, launchOptions: PlatformLaunchOptions) {
                self.application = application
                self.launchOptions = launchOptions
            }
        #endif
    }

    /// `DidUpdateATTrackingStatus` is an action that indicates an update to the App Tracking Transparency (ATT) status.
    public struct DidUpdateATTrackingStatus: Action {
        /// The updated App Tracking Transparency authorization status.
        public let status: ATTrackingManager.AuthorizationStatus

        /// Initializes a new `DidUpdateATTrackingStatus` action.
        ///
        /// - Parameter status: The new ATT authorization status.
        public init(status: ATTrackingManager.AuthorizationStatus) {
            self.status = status
        }
    }
}

// MARK: - Location actions
public extension Actions {
    /// `RequestLocationAccess` is an action that indicates a request to access the user's location.
    struct RequestLocationAccess: Action {
        /// Initializes a new `RequestLocationAccess` action.
        public init() {}
    }

    /// `DidUpdateLocationAccess` is an action that indicates an update to the location access status.
    struct DidUpdateLocationAccess: Action {
        /// Indicates if location services are enabled.
        public var locationServicesEnabled: Bool

        /// The current authorization status for location access.
        public var access: CLAuthorizationStatus

        /// The current accuracy authorization for location access.
        public var accuracyAuthorization: CLAccuracyAuthorization

        /// Initializes a new `DidUpdateLocationAccess` action.
        ///
        /// - Parameters:
        ///   - locationServicesEnabled: A Boolean value indicating if location services are enabled.
        ///   - access: The current location authorization status.
        ///   - accuracyAuthorization: The accuracy authorization status for location access.
        public init(locationServicesEnabled: Bool, access: CLAuthorizationStatus, accuracyAuthorization: CLAccuracyAuthorization) {
            self.locationServicesEnabled = locationServicesEnabled
            self.access = access
            self.accuracyAuthorization = accuracyAuthorization
        }
    }

    /// `DidUpdateUserLocation` is an action that indicates an update to the user's current location.
    struct DidUpdateUserLocation: Action {
        /// The updated user location.
        public var location: CLLocation

        /// Initializes a new `DidUpdateUserLocation` action.
        ///
        /// - Parameter location: The user's new location.
        public init(location: CLLocation) {
            self.location = location
        }
    }
}

// MARK: - Items
public extension Actions {
    /// `DidLoadItem` is an action that represents a single item being loaded.
    struct DidLoadItem<M: Equatable & Sendable>: Action {
        /// The item that was loaded.
        public var item: M

        /// An optional identifier for the loaded item.
        public var id: AnyHashable?

        /// Initializes a new `DidLoadItem` action.
        ///
        /// - Parameter item: The item that was loaded.
        public init(item: M) {
            self.item = item
        }

        /// Initializes a new `DidLoadItem` action with an identifier.
        ///
        /// - Parameters:
        ///   - item: The item that was loaded.
        ///   - id: An identifier for the loaded item.
        public init(item: M, id: some Hashable) {
            self.item = item
            self.id = AnyHashable(id)
        }
    }

    /// `DidLoadItems` is an action that represents multiple items being loaded.
    struct DidLoadItems<M: Equatable & Sendable>: Action {
        /// The list of items that were loaded.
        public var items: [M]

        /// An identifier for the loaded items.
        public var id: AnyHashable

        /// A flag indicating whether a short description should be used for the items.
        public var shortDescription: Bool

        /// Initializes a new `DidLoadItems` action.
        ///
        /// - Parameters:
        ///   - items: The list of items that were loaded.
        ///   - id: An identifier for the loaded items.
        ///   - shortDescription: A flag indicating whether to use a short description. Defaults to `true`.
        public init(items: [M], id: some Hashable, shortDescription: Bool = true) {
            self.items = items
            self.id = AnyHashable(id)
            self.shortDescription = shortDescription
        }

        /// A textual representation of the `DidLoadItems` action.
        public var description: String {
            guard shortDescription else {
                return "DidLoadItems<\(M.self)>(itemsCount: \(items.count), items:\n\t\t\t\t\t\(items.map { String(describing: $0) }.joined(separator: "\n\t\t\t\t\t")))\n"
            }

            return "DidLoadItems<\(M.self)>(count: \(items.count), prefix(1): \(String(describing: items.prefix(1)))"
        }
    }

    /// `DidUpdateItem` is an action that represents an item being updated.
    struct DidUpdateItem<M: Equatable & Sendable>: Action {
        /// The item that was updated.
        public var item: M

        /// An optional identifier for the updated item.
        public var id: AnyHashable?

        /// Initializes a new `DidUpdateItem` action.
        ///
        /// - Parameter item: The item that was updated.
        public init(item: M) {
            self.item = item
        }

        /// Initializes a new `DidUpdateItem` action with an identifier.
        ///
        /// - Parameters:
        ///   - item: The item that was updated.
        ///   - id: An identifier for the updated item.
        public init(item: M, id: some Hashable) {
            self.item = item
            self.id = AnyHashable(id)
        }
    }

    /// `DeleteItem` is an action that represents an item being deleted.
    struct DeleteItem<M: Equatable & Sendable>: Action {
        /// The item that was deleted.
        public var item: M

        /// An optional identifier for the deleted item.
        public var id: AnyHashable?

        /// Initializes a new `DeleteItem` action.
        ///
        /// - Parameter item: The item that was deleted.
        public init(item: M) {
            self.item = item
        }

        /// Initializes a new `DeleteItem` action with an identifier.
        ///
        /// - Parameters:
        ///   - item: The item that was deleted.
        ///   - id: An identifier for the deleted item.
        public init(item: M, id: some Hashable) {
            self.item = item
            self.id = AnyHashable(id)
        }
    }
}

// MARK: - Nested Items
public extension Actions {
    /// `DidLoadNestedItem` is an action that represents a nested item being loaded.
    struct DidLoadNestedItem<ParentId: Hashable & Sendable, Nested: Equatable & Sendable>: Action {
        /// The nested item that was loaded.
        public var item: Nested

        /// An optional identifier for the nested item.
        public var id: AnyHashable?

        /// The identifier of the parent item.
        public var parentId: ParentId

        /// Initializes a new `DidLoadNestedItem` action.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent item.
        ///   - item: The nested item that was loaded.
        public init(parentId: ParentId, item: Nested) {
            self.item = item
            self.parentId = parentId
        }

        /// Initializes a new `DidLoadNestedItem` action with an identifier.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent item.
        ///   - item: The nested item that was loaded.
        ///   - id: An identifier for the nested item.
        public init(parentId: ParentId, item: Nested, id: some Hashable) {
            self.item = item
            self.id = AnyHashable(id)
            self.parentId = parentId
        }
    }

    /// `DidLoadNestedItems` is an action that represents multiple nested items being loaded.
    struct DidLoadNestedItems<ParentId: Hashable & Sendable, Nested: Equatable & Sendable>: Action, CustomStringConvertible {
        /// The nested items that were loaded.
        public var items: [Nested]

        /// An optional identifier for the nested items.
        public var id: AnyHashable?

        /// A flag indicating whether to use a short description for the items.
        public var shortDescription: Bool

        /// The identifier of the parent item.
        public var parentId: ParentId

        /// Initializes a new `DidLoadNestedItems` action.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent item.
        ///   - items: The nested items that were loaded.
        ///   - shortDescription: A flag to indicate if a short description should be used. Default is `true`.
        public init(parentId: ParentId, items: [Nested], shortDescription: Bool = true) {
            self.items = items
            self.shortDescription = shortDescription
            self.parentId = parentId
        }

        /// Initializes a new `DidLoadNestedItems` action with an identifier.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent item.
        ///   - items: The nested items that were loaded.
        ///   - id: An identifier for the nested items.
        ///   - shortDescription: A flag to indicate if a short description should be used. Default is `true`.
        public init(parentId: ParentId, items: [Nested], id: some Hashable, shortDescription: Bool = true) {
            self.items = items
            self.id = AnyHashable(id)
            self.shortDescription = shortDescription
            self.parentId = parentId
        }

        /// A textual representation of the nested items.
        public var description: String {
            guard shortDescription else {
                return "DidLoadNestedItems<\(Nested.self)> Parent: \(String(reflecting: ParentId.self))(\(parentId)) (itemsCount: \(items.count), items:\n\t\t\t\t\t\(items.map { String(describing: $0) }.joined(separator: "\n\t\t\t\t\t")))\n"
            }

            return "DidLoadNestedItems<\(Nested.self)> Parent: \(String(reflecting: ParentId.self))(\(parentId)) (count: \(items.count), prefix(1): \(String(describing: items.prefix(1))))"
        }
    }

    /// `DidLoadNestedByParents` is an action representing the loading of nested items grouped by their parent identifiers.
    struct DidLoadNestedByParents<ParentId: Hashable & Sendable, Nested: Equatable & Sendable>: Action, CustomStringConvertible {
        /// A dictionary mapping parent identifiers to their corresponding nested items.
        public var dictionary: [ParentId: [Nested]]

        /// An optional identifier for this action.
        public var id: AnyHashable?

        /// A flag indicating whether to use a short description for the nested items.
        public var shortDescription: Bool

        /// Initializes a new `DidLoadNestedByParents` action.
        ///
        /// - Parameters:
        ///   - dictionary: A dictionary containing parent identifiers and their corresponding nested items.
        ///   - shortDescription: A flag to indicate if a short description should be used. Default is `true`.
        public init(dictionary: [ParentId: [Nested]], shortDescription: Bool = true) {
            self.shortDescription = shortDescription
            self.dictionary = dictionary
        }

        /// Initializes a new `DidLoadNestedByParents` action with an identifier.
        ///
        /// - Parameters:
        ///   - dictionary: A dictionary containing parent identifiers and their corresponding nested items.
        ///   - id: An identifier for this action.
        ///   - shortDescription: A flag to indicate if a short description should be used. Default is `true`.
        public init(dictionary: [ParentId: [Nested]], id: some Hashable, shortDescription: Bool = true) {
            self.id = AnyHashable(id)
            self.shortDescription = shortDescription
            self.dictionary = dictionary
        }

        /// A textual representation of the nested items.
        public var description: String {
            let parentKeys = dictionary.keys.map { String(describing: $0) }.joined(separator: ", ")
            guard shortDescription else {
                return "DidLoadNestedByParents<\(Nested.self)> Parents: \(String(reflecting: ParentId.self)) [\(parentKeys)] (parentCount: \(dictionary.keys.count), items:\n\t\t\t\t\t\(dictionary.map { String(describing: $0) }.joined(separator: "\n\t\t\t\t\t")))\n"
            }

            return "DidLoadNestedByParents<\(Nested.self)> Parents: \(String(reflecting: ParentId.self)) [\(parentKeys)] (parentCount: \(dictionary.keys.count), prefix(1): \(String(describing: dictionary.prefix(1))))"
        }
    }

    /// `DidUpdateNestedItem` is an action representing the update of a nested item for a specific parent identifier.
    struct DidUpdateNestedItem<ParentId: Hashable & Sendable, Nested: Equatable & Sendable>: Action {
        /// The nested item that was updated.
        public var item: Nested

        /// An optional identifier for this action.
        public var id: AnyHashable?

        /// The identifier of the parent to which the nested item belongs.
        public var parentId: ParentId

        /// Initializes a new `DidUpdateNestedItem` action.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent to which the nested item belongs.
        ///   - item: The nested item that was updated.
        public init(parentId: ParentId, item: Nested) {
            self.item = item
            self.parentId = parentId
        }

        /// Initializes a new `DidUpdateNestedItem` action with an identifier.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent to which the nested item belongs.
        ///   - item: The nested item that was updated.
        ///   - id: An identifier for this action.
        public init(parentId: ParentId, item: Nested, id: some Hashable) {
            self.item = item
            self.id = AnyHashable(id)
            self.parentId = parentId
        }
    }

    /// `DeleteNestedItem` is an action representing the deletion of a nested item for a specific parent identifier.
    struct DeleteNestedItem<ParentId: Hashable & Sendable, Nested: Equatable & Sendable>: Action {
        /// The nested item that is to be deleted.
        public var item: Nested

        /// An optional identifier for this action.
        public var id: AnyHashable?

        /// The identifier of the parent to which the nested item belongs.
        public var parentId: ParentId

        /// Initializes a new `DeleteNestedItem` action.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent to which the nested item belongs.
        ///   - item: The nested item that is to be deleted.
        public init(parentId: ParentId, item: Nested) {
            self.item = item
            self.parentId = parentId
        }

        /// Initializes a new `DeleteNestedItem` action with an identifier.
        ///
        /// - Parameters:
        ///   - parentId: The identifier of the parent to which the nested item belongs.
        ///   - item: The nested item that is to be deleted.
        ///   - id: An identifier for this action.
        public init(parentId: ParentId, item: Nested, id: some Hashable) {
            self.item = item
            self.id = AnyHashable(id)
            self.parentId = parentId
        }
    }
}

// MARK: - Navigation Equality Helper
private func arePathsEqual(_ lhs: [any Hashable & Sendable], _ rhs: [any Hashable & Sendable]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (l, r) in zip(lhs, rhs) {
        if AnyHashable(l) != AnyHashable(r) {
            return false
        }
    }
    return true
}

// MARK: - Global Navigation
public extension Actions {
    /// `Navigate` is an action used to handle navigation to a specific path within the app.
    struct Navigate: Action {
        public static func == (lhs: Actions.Navigate, rhs: Actions.Navigate) -> Bool {
            arePathsEqual(lhs.to, rhs.to)
        }


        /// An array representing the path to navigate to.
        public let to: [any Hashable & Sendable]

        /// Initializes a `Navigate` action to a single destination.
        ///
        /// - Parameter to: A `Hashable` representing the destination.
        public init(to: any Hashable & Sendable) {
            self.to = [to]
        }

        /// Initializes a `Navigate` action to a series of destinations.
        ///
        /// - Parameter path: An array of `Hashable` objects representing the navigation path.
        public init(path: [any Hashable & Sendable]) {
            self.to = path
        }
    }

    /// `NavigateResetStack` is an action used to reset the navigation stack and navigate to a specified path.
    struct NavigateResetStack: Action {
        public static func == (lhs: Actions.NavigateResetStack, rhs: Actions.NavigateResetStack) -> Bool {
            arePathsEqual(lhs.to, rhs.to)
        }

        /// An array representing the path to navigate to after resetting the stack.
        public let to: [any Hashable & Sendable]

        /// Initializes a `NavigateResetStack` action to a single destination.
        ///
        /// - Parameter to: A `Hashable` representing the destination.
        public init(to: any Hashable & Sendable) {
            self.to = [to]
        }

        /// Initializes a `NavigateResetStack` action to a series of destinations.
        ///
        /// - Parameter path: An array of `Hashable` objects representing the navigation path.
        public init(path: [any Hashable & Sendable]) {
            self.to = path
        }
    }

    /// `NavigationBackToRoot` is an action used to navigate back to the root of the navigation stack.
    struct NavigationBackToRoot: Action {
        public init() {}
    }

    /// `NavigateBack` is an action used to handle navigation back to the previous screen.
    struct NavigateBack: Action {
        public init() {}
    }

    /// `NavigateBack` is an action used to handle navigation back a specified number of steps.
    struct NavigateStepsBack: Action {
        public let stepsCount: Int

        public init(stepsCount: Int) {
            self.stepsCount = stepsCount
        }
    }
}

// MARK: - Global Navigation Typed
public extension Actions {
    /// `NavigateTyped` is a generic action used to handle typed navigation to a specific path within the app.
    struct NavigateTyped<Routing>: Action {
        public static func == (lhs: Actions.NavigateTyped<Routing>, rhs: Actions.NavigateTyped<Routing>) -> Bool {
            arePathsEqual(lhs.to, rhs.to)
        }

        /// An array representing the path to navigate to.
        public let to: [any Hashable & Sendable]

        /// Initializes a `NavigateTyped` action to a single destination.
        ///
        /// - Parameter to: A `Hashable` representing the destination.
        public init(to: any Hashable & Sendable) {
            self.to = [to]
        }

        /// Initializes a `NavigateTyped` action to a series of destinations.
        ///
        /// - Parameter path: An array of `Hashable` objects representing the navigation path.
        public init(path: [any Hashable & Sendable]) {
            self.to = path
        }
    }

    /// `NavigateResetStackTyped` is a generic action used to reset the navigation stack and navigate to a specified path.
    struct NavigateResetStackTyped<Routing>: Action {
        public static func == (lhs: Actions.NavigateResetStackTyped<Routing>, rhs: Actions.NavigateResetStackTyped<Routing>) -> Bool {
            arePathsEqual(lhs.to, rhs.to)
        }

        /// An array representing the path to navigate to after resetting the stack.
        public let to: [any Hashable & Sendable]

        /// Initializes a `NavigateResetStackTyped` action to a single destination.
        ///
        /// - Parameter to: A `Hashable` representing the destination.
        public init(to: any Hashable & Sendable) {
            self.to = [to]
        }

        /// Initializes a `NavigateResetStackTyped` action to a series of destinations.
        ///
        /// - Parameter path: An array of `Hashable` objects representing the navigation path.
        public init(path: [any Hashable & Sendable]) {
            self.to = path
        }
    }

    /// `NavigationBackToRootTyped` is a generic action used to navigate back to the root of the navigation stack for a specific `Routing`.
    struct NavigationBackToRootTyped<Routing>: Action {
        public init() {}
    }

    /// `NavigateBackTyped` is a generic action used to handle navigation back to the previous screen for a specific `Routing`.
    struct NavigateBackTyped<Routing>: Action {
        public init() {}
    }

    /// `NavigateStepsBackTyped` is a generic action used to handle navigation back a specified number of steps.
    struct NavigateStepsBackTyped<Routing>: Action {
        public let stepsCount: Int

        public init(stepsCount: Int) {
            self.stepsCount = stepsCount
        }
    }
}

// MARK: BindableReducer internal actions
extension Actions {
    /// `_OnContainerDidLoad` is an internal action used to signal that a `BindableContainer` has loaded.
    ///
    /// This action is typically dispatched when a container of type `BindableContainer` is fully loaded and ready for interactions.
    ///
    struct _OnContainerDidLoad<ID: Hashable & Sendable>: _AnyBindableContainerAction {
        static func == (lhs: Actions._OnContainerDidLoad<ID>, rhs: Actions._OnContainerDidLoad<ID>) -> Bool {
            lhs.id == rhs.id && lhs.containerType == rhs.containerType
        }

        /// The type of the container that has loaded.
        var containerType: Any.Type

        /// The unique identifier of the container.
        var id: ID

        init(containerType: Any.Type, id: ID) {
            self.containerType = containerType
            self.id = id
        }

        init<Container: BindableContainer>(
            containerType: Container.Type,
            id: Container.ID
        ) where Container.ID == ID {
            self.containerType = containerType
            self.id = id
        }

        var anyID: AnyHashable {
            id
        }
    }

    /// `_OnContainerDidUnLoad` is an internal action used to signal that a `BindableContainer` has unloaded.
    ///
    /// This action is typically dispatched when a container of type `BindableContainer` is unloaded, indicating the end of its lifecycle.
    ///
    struct _OnContainerDidUnLoad<ID: Hashable & Sendable>: _AnyBindableContainerAction {
        static func == (lhs: Actions._OnContainerDidUnLoad<ID>, rhs: Actions._OnContainerDidUnLoad<ID>) -> Bool {
            lhs.id == rhs.id && lhs.containerType == rhs.containerType
        }

        /// The type of the container that has unloaded.
        var containerType: Any.Type

        /// The unique identifier of the container.
        var id: ID

        init(containerType: Any.Type, id: ID) {
            self.containerType = containerType
            self.id = id
        }

        init<Container: BindableContainer>(
            containerType: Container.Type,
            id: Container.ID
        ) where Container.ID == ID {
            self.containerType = containerType
            self.id = id
        }

        var anyID: AnyHashable {
            id
        }
    }

    /// `_BindableAction` is an internal action that wraps another action and associates it with a specific `BindableContainer`.
    ///
    /// This is useful for dispatching actions that need to be bound to a particular instance of a container.
    ///
    struct _BindableAction<ID: Hashable & Sendable>: _AnyBindableAction {
        /// The wrapped action that is being bound to the container.
        let value: any Action

        /// The type of the container that the action is bound to.
        let containerType: Any.Type

        /// The unique identifier of the container.
        let id: ID

        init(
            value: any Action,
            containerType: Any.Type,
            id: ID
        ) {
            self.value = value
            self.containerType = containerType
            self.id = id
        }

        init<Container: BindableContainer>(
            value: any Action,
            containerType: Container.Type,
            id: Container.ID
        ) where Container.ID == ID {
            self.value = value
            self.containerType = containerType
            self.id = id
        }

        var anyID: AnyHashable {
            id
        }

        public static func == (lhs: _BindableAction, rhs: _BindableAction) -> Bool {
            lhs.id == rhs.id && areEqual(lhs.value, rhs.value) && lhs.containerType == rhs.containerType
        }

        var description: String {
            "\(value) binded for \(containerType) by \(id)"
        }
    }
}
