import Foundation

/// A protocol that represents an action which can be bound to a specific `BindableContainer`.
///
/// `_AnyBindableAction` is designed to be a base protocol for actions that are associated with
/// a specific `BindableContainer` type. This protocol defines the properties necessary for
/// identifying the bound container and encapsulates the action to be executed.
///
/// - Note: This protocol is intended for internal use and is not meant to be used directly by consumers.
/// - Requirements:
///   - The conforming action must specify a `BindableContainer` type and an associated `ID`.
///
/// - Properties:
///   - `value`: The encapsulated action that is associated with the bindable container.
///   - `containerType`: The type of the `BindableContainer` that this action is associated with.
///   - `id`: The unique identifier for the container instance to which this action is bound.
protocol _AnyBindableAction: Action {
    associatedtype BindedContainer: BindableContainer

    /// The encapsulated action that will be executed for the bound container.
    var value: any Action { get }

    /// The type of the `BindableContainer` associated with this action.
    var containerType: BindedContainer.Type { get }

    /// The unique identifier for the container instance this action is bound to.
    var id: BindedContainer.ID { get }
}
