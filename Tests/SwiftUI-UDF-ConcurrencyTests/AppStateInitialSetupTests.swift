
@testable import UDF
import XCTest

final class AppStateInitialSetupTests: XCTestCase {
    struct AppState: AppReducer {
        var form1 = Form1()
        var form2 = Form2()
    }

    struct Form1: Form, InitialSetup {
        var title: String = ""

        mutating func initialSetup(with state: AppState) {
            title = "new title"
        }
    }

    struct Form2: Form, InitialSetup {
        var nameWithValue: String = "name"
        var nested = NestedForm()

        mutating func initialSetup(with state: AppState) {
            nameWithValue += state.form1.title
        }
    }

    struct NestedForm: Form, InitialSetup {
        var number: Int = 0

        mutating func initialSetup(with state: AppState) {
            number = 2
        }
    }

    func test_initialSetups() async {
        let store = await XCTestStore(initial: AppState())

        let title = await store.state.form1.title
        XCTAssertEqual(title, "new title")

        let name = await store.state.form2.nameWithValue
        XCTAssertEqual(name, "namenew title")

        let nestedNumber = await store.state.form2.nested.number
        XCTAssertEqual(nestedNumber, 2)
    }
}
