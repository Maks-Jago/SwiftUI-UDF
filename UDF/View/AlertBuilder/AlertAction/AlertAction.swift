
import Foundation
import SwiftUI

public protocol AlertAction: Hashable {}

extension AlertAction {
    func mutate(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
