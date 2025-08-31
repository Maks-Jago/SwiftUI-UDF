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
        let store = await TestStore(initial: AppState())

        await store.subscribe(build: { _ in
            TestMiddleware.self
            TestMiddleware.self
        })

        await store.dispatch(TestAction())
        await waitForCondition { await store.state.testForm.reduceCallCount == 1 }
        await sleep()

        let middlewaresCount = await store.state.testForm.reduceCallCount
        #expect(middlewaresCount == 1, "Middleware should only be added once")
    }
}
