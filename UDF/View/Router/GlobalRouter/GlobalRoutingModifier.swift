
import Foundation
import SwiftUI

struct GlobalRoutingModifier<R: Routing>: ViewModifier where R.Route: Hashable {
    @Environment(\.globalRouter) var globalRouter

    var router: Router<R>

    init(router: Router<R>) {
        self.router = router
    }

    func body(content: Content) -> some View {
        let _ = self.globalRouter.add(router: router)
        content
            .navigationDestination(
                for: R.Route.self,
                destination: router.view(for:)
            )
    }
}
