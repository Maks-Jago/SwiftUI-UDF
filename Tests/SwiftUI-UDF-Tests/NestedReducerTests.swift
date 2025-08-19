
import Combine
import CoreLocation
import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite struct NestedReducerTests {
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

    var cancellation: AnyCancellable? = nil

    @Test func appState() async {
        let store = await TestStore(initial: AppState())

        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "temp"))
        var success = await waitForAsyncCondition { await store.state.nested.testForm.title == "temp" }
        #expect(success)

        await store.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: "temp_21"))
        success = await waitForAsyncCondition { await store.state.nested.testForm.title == "temp_21" }
        #expect(success)

        // TODO: This is the original code and just fulfill here. For what?
        // await fulfill(description: "locationFlow must be in `requestPermissions` case", sleep: 1)
    }
}
