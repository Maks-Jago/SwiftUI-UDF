
@testable import UDF
import Testing

@Suite struct AppStateInitialSetupTests {
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

    @Test func initialSetups() async {
        let store = await TestStore(initial: AppState())

        let title = await store.state.form1.title
        #expect(title == "new title")

        let name = await store.state.form2.nameWithValue
        #expect(name == "namenew title")

        let nestedNumber = await store.state.form2.nested.number
        #expect(nestedNumber == 2)
    }
}
