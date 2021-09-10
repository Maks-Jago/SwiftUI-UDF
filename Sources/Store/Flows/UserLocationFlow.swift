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

    public var notDetermined: Bool {
        if case .locationStatus(let status) = self, status == .notDetermined {
            return true
        }

        return false
    }

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
