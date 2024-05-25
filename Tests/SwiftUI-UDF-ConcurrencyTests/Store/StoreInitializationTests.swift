//
//  EnvironmentStoreInitializationTests.swift
//  SwiftUI-UDF-ConcurrencyTests
//
//  Created by Max Kuznetsov on 20.10.2022.
//

import XCTest
@testable import UDF

final class StoreInitializationTests: XCTestCase {

    struct AppState: AppReducer {

        var form1 = Form1()

        struct Form1: Reducible {
            var title: String = ""
        }

        func postReduce(_ action: some Action) {
            print("postReduce: \(action)")
        }
    }

    final class Middleware1: Middleware {
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

        func cancel<Id>(by cancelation: Id) -> Bool where Id : Hashable {
            true
        }

        func cancelAll() {

        }

        func reduce(_ action: some Action, for state: AppState) {
            
        }
    }

    final class Middleware2: Middleware {
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

        func cancel<Id>(by cancelation: Id) -> Bool where Id : Hashable {
            true
        }

        func cancelAll() {

        }

        func reduce(_ action: some Action, for state: AppState) {

        }
    }

    var store: InternalStore<AppState>!

    override func setUpWithError() throws {
        store = try InternalStore(initial: AppState(), loggers: [])
    }

    func test_middlewareAsyncSubscription() async {
        var middlewaresCount = await store.middlewares.count
        XCTAssertEqual(middlewaresCount, 0)

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

        XCTAssertEqual(middlewaresCount, 0)

        await fulfill(description: "Waiting for middlewares subscription", sleep: 0.1)

        middlewaresCount = await store.middlewares.count
        XCTAssertNotEqual(middlewaresCount, 0)
    }

    func test_middlewareSubscription() async {
        var middlewaresCount = await store.middlewares.count
        XCTAssertEqual(middlewaresCount, 0)

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
        XCTAssertNotEqual(middlewaresCount, 0)
    }
}
