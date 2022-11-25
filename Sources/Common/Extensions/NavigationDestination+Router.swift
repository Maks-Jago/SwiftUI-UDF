import Foundation
import SwiftUI

@available(iOS 16.0, *)
public extension View {
    func navigationDestination<R: Routing>(router: Router<R>) -> some View where R.Route: Hashable {
        self
            .navigationDestination(
                for: R.Route.self,
                destination: router.view(for:)
            )
    }
}
