
import Foundation
import enum CoreLocation.CLAuthorizationStatus

extension CLAuthorizationStatus: CustomDebugStringConvertible {
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
