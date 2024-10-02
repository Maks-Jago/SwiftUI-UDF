//
//  Component.swift
//  UDF
//
//  Created by Max Kuznetsov on 04.06.2020.
//  Copyright © 2024 Max Kuznetsov. All rights reserved.
//

import SwiftUI
/// A protocol that represents a reusable view component in SwiftUI.
///
/// Conforming types must define an `associatedtype` called `Props` to represent the data
/// needed to configure the component, and implement a property `props` to hold an instance
/// of this data. The protocol also requires an initializer that accepts a `props` instance.
///
/// By conforming to this protocol, custom SwiftUI views can be created and used as reusable
/// components, each defined by a specific set of properties.
///
/// Example Usage:
/// ```swift
/// struct MyComponent: Component {
///     struct Props {
///         let title: String
///         let subtitle: String
///     }
///
///     var props: Props
///
///     var body: some View {
///         VStack {
///             Text(props.title)
///             Text(props.subtitle)
///         }
///     }
/// }
/// ```
///
/// - Note: This protocol requires conforming types to be SwiftUI `View`s, making it possible
///   to define custom UI components with a structured set of properties.
///
/// ## Requirements:
/// - `Props`: An associated type that defines the properties required by the component.
/// - `props`: A property of the associated type `Props` to hold the configuration data.
/// - Initializer: An initializer that accepts a `Props` instance to configure the component.
public protocol Component: View {
    associatedtype Props
    
    /// The properties used to configure the component.
    var props: Props { get }
    
    /// Initializes the component with the given properties.
    ///
    /// - Parameter props: The properties to use for configuring the component.
    init(props: Props)
}
