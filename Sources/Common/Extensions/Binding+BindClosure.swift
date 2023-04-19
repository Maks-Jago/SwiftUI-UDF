
import SwiftUI

public extension Binding {
    init(_ bind: @autoclosure @escaping () -> Binding<Value>) {
        self.init(
            get: { bind().wrappedValue },
            set: { bind().wrappedValue = $0 }
        )
    }
}
