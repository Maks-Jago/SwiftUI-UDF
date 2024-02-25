//
//  Router.swift
//  SwiftUI-UDF-Binary
//
//  Created by Max Kuznetsov on 08.11.2021.
//

import Foundation
import SwiftUI

public protocol Routing<Route>: Initable {
    associatedtype Route
    associatedtype Destination: View

    func view(for route: Route) -> Self.Destination
}

public final class Router<R: Routing> {
    private typealias MockedBuilder = (_ routing: R, _ route: R.Route) -> AnyView

    public var routing: R
    private var mocker: MockedBuilder?

    public init(routing: R) {
        self.routing = routing
        self.mocker = nil
    }

    public init() {
        self.routing = R.init()
        self.mocker = nil
    }

    public init<MockView: View>(routing: R, @ViewBuilder mocked: @escaping (_ routing: R, _ route: R.Route) -> MockView) {
        self.routing = routing
        self.mocker = { routing, route in
            AnyView(mocked(routing, route))
        }
    }

    @ViewBuilder
    public func view(for route: R.Route) -> some View {
        if let mocker {
            mocker(routing, route)
        } else {
            routing.view(for: route)
        }
    }
}
