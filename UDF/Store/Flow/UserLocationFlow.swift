//===--- UserLocationFlow.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import enum CoreLocation.CLAuthorizationStatus
import enum CoreLocation.CLAccuracyAuthorization

/// A flow that manages the state of user location permissions in the application.
///
/// `UserLocationFlow` is a `Reducible` flow that handles actions related to requesting and updating the user's location permissions.
/// It tracks the state of location access, including authorization status and accuracy.
public enum UserLocationFlow: Reducible {
    
    /// Represents the various states of the user location flow.
    case none
    case requestPermissions
    case locationStatus(locationServicesEnabled: Bool, authorizationStatus: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization)
    
    /// Default initializer for the flow, setting the state to `.none`.
    public init() { self = .none }
    
    /// A computed property to check if the authorization status is not determined.
    public var notDetermined: Bool {
        if case .locationStatus(_, let status, _) = self, status == .notDetermined {
            return true
        }
        return false
    }
    
    /// Reduces the current state based on the provided action.
    ///
    /// This method handles actions related to location access, updating the flow's state accordingly:
    /// - `Actions.RequestLocationAccess`: Transitions the state to `requestPermissions`.
    /// - `Actions.DidUpdateLocationAccess`: Updates the state with the latest location services status, authorization status, and accuracy.
    ///
    /// - Parameter action: The action to reduce.
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
