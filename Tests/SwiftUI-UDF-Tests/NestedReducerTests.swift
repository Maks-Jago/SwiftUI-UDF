
import XCTest
@testable import UDF
import Combine
import CoreLocation
import SwiftUI
import UDFXCTest

final class NestedReducerTests: XCTestCase {

    struct AppState: AppReducer {
        var nested: NestedReducer = .init()
    }

    struct TestForm: UDF.Form, Codable {
        var title: String = ""
    }

    struct NestedReducer: Reducible, Codable {
        var testForm = TestForm()
    }

    enum UserLocationFlow: Reducible {
        case none
        case requestPermissions
        case locationStatus(CLAuthorizationStatus)

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case is RequestUserLocationAccess:
                self = .requestPermissions

            case let action as DidUpdateLocationAccess:
                if action.access == .notDetermined {
                    self = .requestPermissions
                } else {
                    self = .locationStatus(action.access)
                }

            default:
                break
            }
        }
    }

    struct RequestUserLocationAccess: Action {}

    struct DidUpdateLocationAccess: Action {
        public var access: CLAuthorizationStatus

        public init(access: CLAuthorizationStatus) {
            self.access = access
        }
    }

    struct DidUpdateUserLocation: Action {
        public var location: CLLocation

        public init(location: CLLocation) {
            self.location = location
        }
    }

    var cancelation: AnyCancellable? = nil

    func testAppState() async throws {
        let store = try await XCTestStore(initial: AppState())
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "temp"))
        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "temp_21"))

        let title = await store.state.nested.testForm.title

        XCTAssertEqual(title, "temp_21")

        await fulfill(description: "locationFlow must be in `requestPermissions` case", sleep: 1)
    }
}
