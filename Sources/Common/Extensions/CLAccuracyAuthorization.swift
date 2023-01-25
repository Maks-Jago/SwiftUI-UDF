import Foundation
import enum CoreLocation.CLAccuracyAuthorization

extension CLAccuracyAuthorization: CustomDebugStringConvertible {
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

