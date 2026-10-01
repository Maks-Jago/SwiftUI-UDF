import Foundation
import Testing
@testable import UDF

#if os(macOS)
    @Suite struct FeatureMiddlewareDiagnosticsTests {
        @Test("A middleware provider bound to another root state traps with a useful diagnostic")
        func mismatchedRootStateFailsFast() async throws {
            let result = try await #require(
                processExitsWith: .failure,
                observing: [\.standardErrorContent]
            ) {
                _ = EnvironmentStore(initial: MismatchedHostState(), loggers: [])
            }

            let standardError = String(decoding: result.standardErrorContent, as: UTF8.self)
            #expect(standardError.contains("must use MismatchedHostState as its AppState"))
        }

        #if DEBUG
            @Test("A middleware provider nested below a root property traps with its mount path")
            func nestedProviderFailsFast() async throws {
                let result = try await #require(
                    processExitsWith: .failure,
                    observing: [\.standardErrorContent]
                ) {
                    _ = EnvironmentStore(initial: NestedProviderHostState(), loggers: [])
                }

                let standardError = String(decoding: result.standardErrorContent, as: UTF8.self)
                #expect(standardError.contains("mounted at 'container.provider'"))
                #expect(standardError.contains("Mount it directly in the app state instead"))
            }
        #endif
    }

    // MARK: - Wrong root fixture

    private struct MismatchedHostState: AppReducer {
        var provider = ForeignRootProvider()
    }

    private struct ForeignRootState: AppReducer {}

    private struct ForeignRootProvider: Reducible, MiddlewareRegistering {
        typealias AppState = ForeignRootState

        static func registerMiddlewares(
            in store: any Store<ForeignRootState>
        ) -> [MiddlewareWrapper<ForeignRootState>] {}
    }

    // MARK: - Nested provider fixture

    private struct NestedProviderHostState: AppReducer {
        var container = ProviderContainer()
    }

    private struct ProviderContainer: Reducible {
        var provider = NestedProvider()
    }

    private struct NestedProvider: Reducible, MiddlewareRegistering {
        typealias AppState = NestedProviderHostState

        static func registerMiddlewares(
            in store: any Store<NestedProviderHostState>
        ) -> [MiddlewareWrapper<NestedProviderHostState>] {}
    }
#endif
