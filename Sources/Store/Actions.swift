//
//  Actions.swift
//  
//
//  Created by Max Kuznetsov on 31.08.2021.
//

import Foundation
import SwiftUI_UDF_Binary
import CoreLocation

// MARK: - Location actions
public extension Actions {
    struct RequestLocationAccess: EquatableAction {
        public init() {}
    }

    struct DidUpdateLocationAccess: EquatableAction {
        public var access: CLAuthorizationStatus

        public init(access: CLAuthorizationStatus) {
            self.access = access
        }
    }

    struct DidUpdateUserLocation: EquatableAction {
        public var location: CLLocation

        public init(location: CLLocation) {
            self.location = location
        }
    }
}
