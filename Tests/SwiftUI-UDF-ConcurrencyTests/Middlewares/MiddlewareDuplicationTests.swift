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
            if action is Actions.RecordMiddlewareCall {
                reduceCallCount += 1
            }
        }
    }

    final class TestMiddleware: Middleware<AppState>, @unchecked Sendable {
        var environment: Void!

        func reduce(_ action: some Action, for state: AppState) {
            switch action {
            case is Actions.TestAction:
                store.dispatch(Actions.RecordMiddlewareCall())

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
                await store.subscribe { store in
                    let middleware = TestMiddleware(store: store, environment: ())
                    return [middleware, middleware]
                }
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

            await store.subscribe { _ -> [MiddlewareWrapper<AppState>] in
                TestMiddleware.self
                TestMiddleware.self
            }

            await store.dispatch(Actions.TestAction())
            await store.wait()

            let middlewaresCount = await store.state.testForm.reduceCallCount
            #expect(middlewaresCount == 2)
        }
    #endif
}

// MARK: - Actions

private extension Actions {
    struct TestAction: Action {}
    struct RecordMiddlewareCall: Action {}
}
