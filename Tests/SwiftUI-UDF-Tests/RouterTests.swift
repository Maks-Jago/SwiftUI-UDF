
import SwiftUI
@testable import UDF
import XCTest

final class RouterTests: XCTestCase {
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

    func test_RouterMocking() throws {
        let itemsComponent = ItemsComponent(props: .init())
        let detailsView = itemsComponent.props.router.view(for: .details)

        let detailsTextDesc = "\(detailsView)"
        XCTAssertTrue(detailsTextDesc.contains("\"details\""))

        let mockedRouter = Router(routing: ItemDetailsRouting()) { routing, route in
            switch route {
            case .details: Button(action: {}, label: { Text("mocked button") })
            default: routing.view(for: route)
            }
        }

        let mockedItemsComponent = ItemsComponent(props: .init(router: mockedRouter))
        let mockedDetailsView = mockedItemsComponent.props.router.view(for: .details)

        let mockedDetailsTextDesc = "\(mockedDetailsView)"

        XCTAssertFalse(mockedDetailsTextDesc.contains("\"details\""))
    }
}
