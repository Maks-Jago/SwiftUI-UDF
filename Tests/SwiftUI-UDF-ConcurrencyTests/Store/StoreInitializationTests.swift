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
    struct StoreInitializationAppState: AppReducer {
        var form1 = Form1()

        struct Form1: Reducible {
            var title: String = ""
        }

        func postReduce(_ action: some Action) {
            print("postReduce: \(action)")
        }
    }

    final class Middleware1: _Middleware, @unchecked Sendable {
        var store: any Store<StoreInitializationTests.StoreInitializationAppState>

        var queue: DispatchQueue

        init(store: some Store<StoreInitializationAppState>) {
            self.store = store
            self.queue = .main
        }

        init(store: some Store<StoreInitializationAppState>, queue: DispatchQueue) {
            self.store = store
            self.queue = queue
        }

        func status(for state: StoreInitializationTests.StoreInitializationAppState) -> MiddlewareStatus { .active }

        func cancel(by cancelation: some Hashable) -> Bool {
            true
        }

        func cancelAll() {}

        func reduce(_ action: some Action, for state: StoreInitializationAppState) {}
    }

    final class Middleware2: _Middleware, @unchecked Sendable {
        var store: any Store<StoreInitializationTests.StoreInitializationAppState>

        var queue: DispatchQueue

        init(store: some Store<StoreInitializationAppState>) {
            self.store = store
            self.queue = .main
        }

        init(store: some Store<StoreInitializationAppState>, queue: DispatchQueue) {
            self.store = store
            self.queue = queue
        }

        func status(for state: StoreInitializationTests.StoreInitializationAppState) -> MiddlewareStatus { .active }

        func cancel(by cancelation: some Hashable) -> Bool {
            true
        }

        func cancelAll() {}

        func reduce(_ action: some Action, for state: StoreInitializationAppState) {}
    }

    var store: InternalStore<StoreInitializationAppState>!

    init() throws {
        store = InternalStore(initial: StoreInitializationAppState(), loggers: [])
    }

    @Test func middlewareAsyncSubscription() async {
        var middlewaresCount = await store.middlewares.count
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

        #expect(middlewaresCount == 0)

        await fulfill(description: "Waiting for middlewares subscription", sleep: 0.1)

        middlewaresCount = await store.middlewares.count
        #expect(middlewaresCount != 0)
    }

    @Test func middlewareSubscription() async {
        var middlewaresCount = await store.middlewares.count
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

        middlewaresCount = await store.middlewares.count
        #expect(middlewaresCount != 0)
    }
}
