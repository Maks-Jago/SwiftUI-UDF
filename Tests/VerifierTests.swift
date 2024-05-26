//
//  VerifierTests.swift
//  SwiftUI-UDFTests
//
//  Created by Max Kuznetsov on 12.04.2022.
//

import XCTest
@testable import UDF

fileprivate extension Actions {
    struct Message: Action {
        public var message: String?
        public var id: AnyHashable

        public init<Id: Hashable>(message: String? = nil, id: Id) {
            self.message = message?.isEmpty == true ? nil : message
            self.id = AnyHashable(id)
        }
    }
}

class VerifierTests: XCTestCase {

    struct AppState: AppReducer {}

    var store: XCTestStore<AppState>!

    func testExample() async throws {
        store = try await XCTestStore(initial: AppState())

        //NOTE: Should not be crashed
        await store.dispatch(Actions.Message(id: "message"))
    }
}
