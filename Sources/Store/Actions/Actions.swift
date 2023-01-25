
import Foundation
import SwiftUI_UDF_Binary

import class CoreLocation.CLLocation
import enum CoreLocation.CLAuthorizationStatus
import enum CoreLocation.CLAccuracyAuthorization

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

// MARK: - Location actions
public extension Actions {
    struct RequestLocationAccess: Action {
        public init() {}
    }

    struct DidUpdateLocationAccess: Action {
        public var access: CLAuthorizationStatus
        public var accuracyAuthorization: CLAccuracyAuthorization

        public init(access: CLAuthorizationStatus, accuracyAuthorization: CLAccuracyAuthorization) {
            self.access = access
            self.accuracyAuthorization = accuracyAuthorization
        }
    }

    struct DidUpdateUserLocation: Action {
        public var location: CLLocation

        public init(location: CLLocation) {
            self.location = location
        }
    }
}
