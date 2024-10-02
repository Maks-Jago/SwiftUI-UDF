
import SwiftUI
/// A protocol that defines a reusable component conforming to SwiftUI's `View`.
///
/// `Component` enforces the use of properties (props) to configure the view. Each conforming type
/// must define an associated type `Props` representing the properties needed to initialize and
/// configure the component.
///
/// This protocol simplifies creating reusable and configurable UI components within a SwiftUI-based application.
public protocol Component: View {
    
    /// The type of the properties used to configure the component.
    associatedtype Props
    
    /// The properties used to initialize and configure the component.
    var props: Props { get }
    
    /// Initializes a component with the specified properties.
    ///
    /// - Parameter props: The properties to configure the component.
    init(props: Props)
}
