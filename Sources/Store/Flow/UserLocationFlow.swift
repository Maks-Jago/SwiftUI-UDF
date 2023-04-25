//
//  UserLocationFlow.swift
//  
//
//  Created by Max Kuznetsov on 31.08.2021.
//

import Foundation
import UDFCore
import enum CoreLocation.CLAuthorizationStatus
import enum CoreLocation.CLAccuracyAuthorization

public enum UserLocationFlow: Reducible {
    case none
    case requestPermissions
    case locationStatus(locationServicesEnabled: Bool, authorizationStatus: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization)

    public init() { self = .none }

    public var notDetermined: Bool {
        if case .locationStatus(_, let status, _) = self, status == .notDetermined {
            return true
        }

        return false
    }

    mutating public func reduce(_ action: some Action) {
        switch action {
        case is Actions.RequestLocationAccess:
            self = .requestPermissions

        case let action as Actions.DidUpdateLocationAccess:
            self = .locationStatus(
                locationServicesEnabled: action.locationServicesEnabled,
                authorizationStatus: action.access,
                accuracy: action.accuracyAuthorization
            )

        default:
            break
        }
    }
}
