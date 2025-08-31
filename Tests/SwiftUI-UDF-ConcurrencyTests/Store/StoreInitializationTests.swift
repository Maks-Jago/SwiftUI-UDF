//
//  StoreInitializationTests.swift
//  SwiftUI-UDF-ConcurrencyTests
//
//  Created by Max Kuznetsov on 20.10.2022.
//

@testable import UDF
import Testing
import Foundation
import UDFSwiftTesting

@Suite struct StoreInitializationTests {
    struct AppState: AppReducer {
        var form1 = Form1()

        struct Form1: Reducible {
            var title: String = ""
        }

        func postReduce(_ action: some Action) {
            print("postReduce: \(action)")
        }
    }

    final class Middleware1: _Middleware, @unchecked Sendable {
        var store: any Store<StoreInitializationTests.AppState>

        var queue: DispatchQueue

        init(store: some Store<AppState>) {
            self.store = store
            self.queue = .main
        }

        init(store: some Store<AppState>, queue: DispatchQueue) {
            self.store = store
            self.queue = queue
        }

        func status(for state: StoreInitializationTests.AppState) -> MiddlewareStatus { .active }

        func cancel(by cancelation: some Hashable) -> Bool {
            true
        }

        func cancelAll() {}

        func reduce(_ action: some Action, for state: AppState) {}
    }

    final class Middleware2: _Middleware, @unchecked Sendable {
        var store: any Store<StoreInitializationTests.AppState>

        var queue: DispatchQueue

        init(store: some Store<AppState>) {
            self.store = store
            self.queue = .main
        }

        init(store: some Store<AppState>, queue: DispatchQueue) {
            self.store = store
            self.queue = queue
        }

        func status(for state: StoreInitializationTests.AppState) -> MiddlewareStatus { .active }

        func cancel(by cancelation: some Hashable) -> Bool {
            true
        }

        func cancelAll() {}

        func reduce(_ action: some Action, for state: AppState) {}
    }

    var store: InternalStore<AppState>!

    init() throws {
        store = InternalStore(initial: AppState(), loggers: [])
    }

    @Test func middlewareAsyncSubscription() async {
        let middlewaresCount = await store.middlewares.count
        #expect(middlewaresCount == 0)

        let middleware1 = Middleware1(
            store: store,
            queue: .main
        )

        await store.subscribe(middleware1)

        let middleware = Middleware2(
            store: store,
            queue: .main
        )

        await store.subscribe(middleware)

        let success = await waitForCondition { await store.middlewares.count != 0 }
        #expect(success)
    }

    @Test func middlewareSubscription() async {
        let middlewaresCount = await store.middlewares.count
        #expect(middlewaresCount == 0)

        let middleware1 = Middleware1(
            store: store,
            queue: .main
        )

        await store.subscribe(middleware1)

        let middleware = Middleware2(
            store: store,
            queue: .main
        )

        await store.subscribe(middleware)

        let success = await waitForCondition { await store.middlewares.count != 0 }
        #expect(success)
    }
}
