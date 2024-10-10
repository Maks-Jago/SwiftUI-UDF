//===--- UIWindow+Render.swift --------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

extension UIWindow {
    
    /// Asynchronously renders a `Container` into a `UIWindow`.
    ///
    /// This method creates a new `UIWindow`, sets up a `UIHostingController` with the provided `container`,
    /// and attaches it to the window's root view controller. It triggers appearance transitions and
    /// layout passes to ensure the view is properly rendered.
    ///
    /// - Parameter container: A SwiftUI container that conforms to the `Container` protocol.
    /// - Returns: A `UIWindow` containing the rendered container.
    static func render<C: Container>(container: C) async -> UIWindow {
        await MainActor.run {
            let window = UIWindow(frame: .zero)
            
            // Create a UIHostingController to host the SwiftUI container
            let viewController = UIHostingController(rootView: container)
            window.rootViewController = viewController
            
            // Begin and end appearance transitions to simulate the view appearing on screen
            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()
            
            // Trigger layout passes to ensure the view is rendered properly
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
            
            return window
        }
    }
}
