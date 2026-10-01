@testable import UDF
import UDFSwiftTesting
import Testing

@Suite struct MiddlewareDuplicationTests {
    struct AppState: AppReducer {
        var testForm = TestForm()
    }

    struct TestForm: Form {
        var reduceCallCount = 0

        mutating func reduce(_ action: some Action) {
            if action is RecordMiddlewareCall {
                reduceCallCount += 1
            }
        }
    }

    struct TestAction: Action {}
    struct RecordMiddlewareCall: Action {}

    final class TestMiddleware: Middleware<AppState>, @unchecked Sendable {
        var environment: Void!

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case is TestAction:
                store.dispatch(RecordMiddlewareCall())

            default:
                break
            }
        }
    }

    #if os(macOS) && DEBUG
        @Test("Subscribing the same middleware instance twice traps in debug")
        func repeatedMiddlewareInstanceFailsFast() async throws {
            let result = try await #require(
                processExitsWith: .failure,
                observing: [\.standardErrorContent]
            ) {
                let store = await TestStore(initial: AppState())
                await store.subscribe(buildMiddlewares: { store in
                    let middleware = TestMiddleware(store: store, environment: ())
                    return [middleware, middleware]
                })
            }

            let standardError = String(decoding: result.standardErrorContent, as: UTF8.self)
            #expect(standardError.contains("TestMiddleware"))
            #expect(standardError.contains("is already registered"))
        }
    #endif

    #if !DEBUG
        @Test("Both middleware instances handle actions when registered twice in release")
        func duplicateMiddlewareInstancesHandleActionsInRelease() async {
            let store = await TestStore(initial: AppState())

            await store.subscribe(build: { _ in
                TestMiddleware.self
                TestMiddleware.self
            })

            await store.dispatch(TestAction())
            await store.wait()

            let middlewaresCount = await store.state.testForm.reduceCallCount
            #expect(middlewaresCount == 2)
        }
    #endif
}
