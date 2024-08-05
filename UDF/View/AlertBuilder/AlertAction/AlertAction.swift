
import Foundation
import SwiftUI

public protocol AlertAction: Hashable, Identifiable where ID == AnyHashable {}

extension AlertAction {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension AlertAction {
    func mutate(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
