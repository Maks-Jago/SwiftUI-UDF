//
//  View+NavigationDestination.swift
//  
//
//  Created by Lena Soroka on 06.09.2023.
//

import SwiftUI
import Foundation

#if os(iOS)
public extension View {
    func navigationDestination<R: Routing>(router: Router<R>, selectedRoute: Binding<R.Route?>) -> some View {
        self.navigationDestination(isPresented: selectedRoute.isPresented()) {
            if let route = selectedRoute.wrappedValue {
                router.view(for: route)
            }
        }
    }

    func navigationDestination<R: Routing>(router: Router<R>) -> some View where R.Route: Hashable {
        modifier(GlobalRoutingModifier(router: router))
    }
}

#endif

fileprivate extension Binding {
    func isPresented<T>() -> Binding<Bool> where Value == Optional<T> {
        Binding<Bool>(
            get: {
                switch self.wrappedValue {
                case .some: return true
                case .none: return false
                }
            },
            set: {
                if !$0 {
                    self.wrappedValue = nil
                }
            }
        )
    }
}
