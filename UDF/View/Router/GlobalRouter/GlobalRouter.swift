
import Foundation
import SwiftUI

public final class GlobalRouter {
    private var routingPath: Binding<NavigationPath>
    private var routers: [Weak] = []

    public init(path: Binding<NavigationPath>) {
        self.routingPath = path
    }

    public func add<R: Routing>(router: Router<R>) {
        routers.reap()
        routers.append(.init(value: router))
    }

    public func navigate<R: Routing>(to route: R.Route, with router: Router<R>) where R.Route: Hashable {
        let registeredRoute = routers.first { obj in
            guard let value = obj.value else {
                return false
            }

            return ObjectIdentifier(value) == ObjectIdentifier(router)
        }

        guard registeredRoute != nil else {
            fatalError("Router: \(router) does not attached to the view heirarchy. use `navigationDestination(router:)` to add routerd")
        }

        routers.reap()
        routingPath.wrappedValue.append(route)
    }

    func backToRoot() {
        routingPath.wrappedValue.removeLast(routingPath.wrappedValue.count)
    }

    func back() {
        routingPath.wrappedValue.removeLast()
    }

    func back(stepsCount: Int) {
        routingPath.wrappedValue.removeLast(stepsCount)
    }
}

private struct GlobalRouterKey: EnvironmentKey {
    static var defaultValue: GlobalRouter = GlobalRouter(path: .constant(NavigationPath()))
}

public extension EnvironmentValues {
    var globalRouter: GlobalRouter {
        get { self[GlobalRouterKey.self] }
        set { self[GlobalRouterKey.self] = newValue }
    }
}
