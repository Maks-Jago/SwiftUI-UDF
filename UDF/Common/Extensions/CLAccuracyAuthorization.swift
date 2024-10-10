//===--- CLAccuracyAuthorization.swift ------------------------===//
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
import enum CoreLocation.CLAccuracyAuthorization

extension CLAccuracyAuthorization: CustomDebugStringConvertible {
    /// Provides a custom debug description for the `CLAccuracyAuthorization` enumeration.
    ///
    /// - Returns: A `String` describing the accuracy authorization level.
    public var debugDescription: String {
        switch self {
        case .fullAccuracy:
            return "CLAccuracyAuthorization.fullAccuracy"
            
        case .reducedAccuracy:
            return "CLAccuracyAuthorization.reducedAccuracy"
            
        @unknown default:
            return "\(self)"
        }
    }
}
