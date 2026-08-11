import Combine
import Foundation


/// A protocol that defines a Combine-based effect that receives both a unique flow identifier and the current application state,
/// and produces a publisher of actions.
///
/// `StateEffectable` is the Combine equivalent of `StateConcurrencyEffect`. It is useful when the effect needs both middleware
/// dependencies and a snapshot of the current state in order to build a publisher that emits actions.
public protocol StateEffectable {
    associatedtype Environment: Sendable
    associatedtype AppState: AppReducer

    /// The environment used by the effect to access external dependencies.
    var environment: Environment! { get set }

    /// Creates a publisher using both the provided flow identifier and the current application state.
    ///
    /// - Parameters:
    ///   - flowId: The unique identifier for the flow.
    ///   - state: The current application state captured when the effect begins execution.
    /// - Returns: A publisher that emits actions produced by the effect.
    func publisher(flowId: AnyHashable, state: AppState) -> AnyPublisher<any Action, Never>
}

public extension StateEffectable {
    var environment: Void! {
        get { () }
        set { }
    }
}
