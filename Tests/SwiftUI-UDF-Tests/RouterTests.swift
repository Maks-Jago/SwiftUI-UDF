
import SwiftUI
@testable import UDF
import Testing

@Suite struct RouterTests {
    struct ItemDetailsRouting: Routing {
        enum Route {
            case details
            case someModal
        }

        @ViewBuilder
        func view(for route: Route) -> some View {
            switch route {
            case .details: Text("details")
            case .someModal: Text("some modal")
            }
        }
    }

    struct ItemsComponent: Component {
        struct Props {
            var router: Router<ItemDetailsRouting> = .init()
        }

        var props: Props

        var body: some View {
            Text("body")
                .overlay(props.router.view(for: .details))
        }
    }

    @Test
    @MainActor
    func routerMocking() throws {
        let itemsComponent = ItemsComponent(props: .init())
        let detailsView = itemsComponent.props.router.view(for: .details)

        let detailsTextDesc = "\(detailsView)"
        #expect(detailsTextDesc.contains("\"details\""))

        let mockedRouter = Router(routing: ItemDetailsRouting()) { routing, route in
            switch route {
            case .details: Button(action: {}, label: { Text("mocked button") })
            default: routing.view(for: route)
            }
        }

        let mockedItemsComponent = ItemsComponent(props: .init(router: mockedRouter))
        let mockedDetailsView = mockedItemsComponent.props.router.view(for: .details)

        let mockedDetailsTextDesc = "\(mockedDetailsView)"

        #expect(!mockedDetailsTextDesc.contains("\"details\""))
    }

    @Test func navigateActionEquality() {
        // Test untyped global navigation
        let nav1 = Actions.Navigate(to: "home")
        let nav2 = Actions.Navigate(to: "settings")
        let nav3 = Actions.Navigate(to: "home")
        let nav4 = Actions.Navigate(path: ["home", "details"])
        let nav5 = Actions.Navigate(path: ["home", "details"])
        
        #expect(nav1 != nav2)
        #expect(nav1 == nav3)
        #expect(nav4 == nav5)
        #expect(nav1 != nav4)
        
        // Test untyped reset stack navigation
        let reset1 = Actions.NavigateResetStack(to: "home")
        let reset2 = Actions.NavigateResetStack(to: "settings")
        #expect(reset1 != reset2)
        
        // Test typed navigation
        let typedNav1 = Actions.NavigateTyped<ItemDetailsRouting>(to: ItemDetailsRouting.Route.details)
        let typedNav2 = Actions.NavigateTyped<ItemDetailsRouting>(to: ItemDetailsRouting.Route.someModal)
        let typedNav3 = Actions.NavigateTyped<ItemDetailsRouting>(to: ItemDetailsRouting.Route.details)
        
        #expect(typedNav1 != typedNav2)
        #expect(typedNav1 == typedNav3)
    }

    @Test func heterogeneousNavigatePaths() {
        enum RouteA: Hashable { case home }
        enum RouteB: Hashable { case detail }
        
        let path1 = Actions.Navigate(path: [RouteA.home, RouteB.detail])
        let path2 = Actions.Navigate(path: [RouteA.home, RouteB.detail])
        let path3 = Actions.Navigate(path: [RouteA.home, RouteA.home])
        
        #expect(path1 == path2)
        #expect(path1 != path3)
    }
}
