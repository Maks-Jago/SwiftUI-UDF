//
//  StateCopyTests.swift
//  SwiftUI-UDFTests
//
//  Created by Max Kuznetsov on 23.03.2023.
//

import XCTest
@testable import UDF

final class StateCopyTests: XCTestCase {

    private struct ConsoleLogger: ActionLogger {
        var actionFilters: [ActionFilter] = [VerboseActionFilter()]
        var actionDescriptor: ActionDescriptor = StringDescribingActionDescriptor()

        func log(_ action: LoggingAction, description: String) {
            print("Reduce\t\t", description)
            print("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
        }
    }

    struct AppState: AppReducer {
        var someForm = SomeForm()
    }

    struct SomeForm: Form {
        var item: Item = .init(text: "initial text")
    }

    class Item: Equatable {
        static func == (lhs: StateCopyTests.Item, rhs: StateCopyTests.Item) -> Bool {
            lhs.text == rhs.text
        }

        var text: String

        init(text: String) {
            self.text = text
        }
    }

    func testStateCopying() async {
        let store = await XCTestStore(initial: AppState())
        await store.dispatch(Actions.UpdateFormField(keyPath: \SomeForm.item, value: .init(text: "new item text")))

        let item = await store.state.someForm.item
        XCTAssertEqual(item.text, "new item text")
    }
}
