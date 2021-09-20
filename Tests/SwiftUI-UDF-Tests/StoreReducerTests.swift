//
//  StoreReducerTests.swift
//  
//
//  Created by Max Kuznetsov on 18.08.2021.
//

import XCTest
@testable import SwiftUI_UDF
import Combine

class StoreReducerTests: XCTestCase {
    struct AppState: AppReducer, Equatable {

        var testForm: TestForm = .init()
    }

    struct TestForm: Form {
        var title: String = ""

        mutating func reduce(_ action: AnyAction) {
            switch action.value {
            case let action as Actions.UpdateFormField<Self, String>:
                self[keyPath: action.keyPath] = action.value
            default:
                break
            }
        }
    }

    var cancelation: AnyCancellable? = nil

    func testAppState() {
        let testStore = EnvironmentStore(initial: AppState())
        let newValue = "test title"
        let exp = expectation(description: "test form `title` field should be updated to `\(newValue)`")

//        cancelation = testStore.$state.sink { newState in
//            if newState.testForm.title == newValue {
//                exp.fulfill()
//            }
//        }
        
        testStore.dispatch(Actions.UpdateFormField(keyPath: \TestForm.title, value: newValue))
        waitForExpectations(timeout: 15, handler: nil)
    }
}
