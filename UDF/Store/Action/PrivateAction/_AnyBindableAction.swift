import Foundation

/// A base protocol for internal actions that target a specific bindable container instance.
///
/// `_AnyBindableContainerAction` provides the minimum runtime metadata needed to route an action
/// to the correct `BindableReducer` without depending on a concrete container type at the protocol level.
/// Conforming actions carry:
/// - `containerType`: the runtime type of the target `BindableContainer`
/// - `anyID`: the erased identifier of the target container instance
///
/// This protocol is used internally by bindable reducer infrastructure to match load/unload/bound
/// actions against the reducer collection associated with a container type.
protocol _AnyBindableContainerAction: Action, Identifiable {
    /// The type of the `BindableContainer` that this load action is associated with.
    var containerType: any BindableContainer.Type { get }
}

/// A protocol that represents an action which can be bound to a specific `BindableContainer`.
///
/// `_AnyBindableAction` is designed to be a base protocol for actions that are associated with
/// a specific `BindableContainer` type. This protocol defines the properties necessary for
/// identifying the bound container and encapsulates the action to be executed.
///
/// - Note: This protocol is intended for internal use and is not meant to be used directly by consumers.
/// - Properties:
///   - `value`: The encapsulated action that is associated with the bindable container.
///   - `containerType`: The type of the `BindableContainer` that this action is associated with.
///   - `id`: The unique identifier for the container instance to which this action is bound.
protocol _AnyBindableAction: Action, Identifiable {
    /// The encapsulated action that will be executed for the bound container.
    var value: any Action { get }

    /// The type of the `BindableContainer` associated with this action.
    var containerType: any BindableContainer.Type { get }
}
