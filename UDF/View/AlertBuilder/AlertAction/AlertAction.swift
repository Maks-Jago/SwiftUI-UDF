
import Foundation
import SwiftUI

public protocol AlertAction: Hashable, Identifiable where ID == AnyHashable {}

extension AlertAction {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
