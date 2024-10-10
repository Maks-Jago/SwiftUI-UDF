//===--- CLAuthorizationStatus.swift ------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import enum CoreLocation.CLAuthorizationStatus

extension CLAuthorizationStatus: CustomDebugStringConvertible {
    /// Provides a custom debug description for the `CLAuthorizationStatus` enumeration.
    ///
    /// - Returns: A `String` describing the authorization status.
    public var debugDescription: String {
        switch self {
        case .authorizedAlways:
            return "CLAuthorizationStatus.authorizedAlways"
            
        case .authorizedWhenInUse:
            return "CLAuthorizationStatus.authorizedWhenInUse"
            
        case .denied:
            return "CLAuthorizationStatus.denied"
            
        case .notDetermined:
            return "CLAuthorizationStatus.notDetermined"
            
        case .restricted:
            return "CLAuthorizationStatus.restricted"
            
        @unknown default:
            return "\(self)"
        }
    }
}
