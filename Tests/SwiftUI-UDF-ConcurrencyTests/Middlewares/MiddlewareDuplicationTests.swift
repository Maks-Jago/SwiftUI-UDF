@testable import UDF
import UDFSwiftTesting
import Testing

@Suite struct MiddlewareDuplicationTests {
    struct AppState: AppReducer {
        var testForm = TestForm()
    }

    struct TestForm: Form {
        var reduceCallCount = 0
    }

    struct TestAction: Action {}

    final class TestMiddleware: Middleware<AppState>, @unchecked Sendable {
        var environment: Void!

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case is TestAction:
                store.dispatch(
                    Actions.UpdateFormField(
                        keyPath: \TestForm.reduceCallCount,
                        value: state.testForm.reduceCallCount + 1
                    )
                )

            default:
                break
            }
        }
    }

    @Test func middlewareDuplication() async {
        let store = EnvironmentStore(initial: AppState(), loggers: [])

        store.subscribe(build: { _ in
            TestMiddleware.self
            TestMiddleware.self
        })

        store.dispatch(TestAction())
        await fulfill(description: "waiting for middleware operations", sleep: 0.3)

        // Verify that the middleware is only added once
        let middlewaresCount = store.state.testForm.reduceCallCount
        #expect(middlewaresCount == 1, "Middleware should only be added once")
    }
}
