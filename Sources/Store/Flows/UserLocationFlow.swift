//
//  UserLocationFlow.swift
//  
//
//  Created by Max Kuznetsov on 31.08.2021.
//

import Foundation
import SwiftUI_UDF_Binary
import enum CoreLocation.CLAuthorizationStatus

public enum UserLocationFlow: Reducible {
    case none
    case requestPermissions
    case locationStatus(CLAuthorizationStatus)

    public init() { self = .none }

    mutating public func reduce(_ action: AnyAction) {
        switch action.value {
        case is Actions.RequestLocationAccess:
            self = .requestPermissions

        case let action as Actions.DidUpdateLocationAccess:
            self = .locationStatus(action.access)

        default:
            break
        }
    }
}
