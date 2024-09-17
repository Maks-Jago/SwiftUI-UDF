//
//  UIWindow+Render.swift
//  
//
//  Created by Max Kuznetsov on 07.09.2024.
//

import Foundation
import SwiftUI

extension UIWindow {

    static func render<C: Container>(container: C) async -> UIWindow {
        await MainActor.run {
            let window = UIWindow(frame: .zero)
            let viewController = UIHostingController(rootView: container)
            window.rootViewController = viewController

            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()

            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
            return window
        }
    }
}
