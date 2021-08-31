//
//  Actions.swift
//  
//
//  Created by Max Kuznetsov on 31.08.2021.
//

import Foundation
import SwiftUI_UDF_Binary
import CoreLocation

public extension Actions {
    struct DidUpdateLocationAccess: EquatableAction {
        var access: CLAuthorizationStatus
    }

    struct DidUpdateUserLocation: EquatableAction {
        var location: CLLocation
    }
}
