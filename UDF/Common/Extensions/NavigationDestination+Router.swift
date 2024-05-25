import Foundation
import SwiftUI

#if os(iOS)
public extension View {
    func navigationDestination<R: Routing>(router: Router<R>) -> some View where R.Route: Hashable {
        self
            .navigationDestination(
                for: R.Route.self,
                destination: router.view(for:)
            )
    }
}
#endif
