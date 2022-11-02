
import Foundation
import SwiftUI_UDF_Binary

public extension Actions {
    struct UpdateAlertStatus: Action {
        public var status: AlertBuilder.AlertStatus
        public var id: AnyHashable

        public init<Id: Hashable>(status: AlertBuilder.AlertStatus, id: Id) {
            self.status = status
            self.id = id
        }

        public init<Id: Hashable>(style: AlertBuilder.AlertStyle, id: Id) {
            self.status = .init(style: style)
            self.id = id
        }
    }
}
