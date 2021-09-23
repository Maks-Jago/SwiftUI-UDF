//
//  PaginatorTests.swift
//  
//
//  Created by Max Kuznetsov on 15.09.2021.
//

import XCTest
@testable import SwiftUI_UDF

class PaginatorTests: XCTestCase {

    struct Item: Equatable, Identifiable, Hashable {
        struct Id: Hashable {
            var value: Int
        }

        var id: Id
        var title: String
        var text: String

        init() {
            id = .init(value: .random(in: 0..<Int.max))
            title = "title \(id.value)"
            text = "text \(id.value)"
        }

        static func fakeItems(count: Int) -> [Item] {
            (0..<count).map { _ in Self.init()}
        }
    }

    enum ItemFlow: IdentifiableFlow {
        case none

        init() { self = .none }

        mutating func reduce(_ action: AnyAction) {}
    }

    func testPaginatorPagesRemoving() throws {
        var paginator = Paginator<Item, ItemFlow.FlowId>(flowId: ItemFlow.id, perPage: 10)
        let firstPageItems = Item.fakeItems(count: 10)
        let secondPageItems = Item.fakeItems(count: 10)
        let thirdPageItems = Item.fakeItems(count: 4)

        paginator.reduce(Actions.LoadPage(id: ItemFlow.id).eraseToAnyAction())
        paginator.reduce(Actions.DidLoadItems(items: firstPageItems, id: ItemFlow.id).eraseToAnyAction())
        XCTAssertEqual(paginator.items.count, 10)
        XCTAssertEqual(paginator.page, .number(1))

        paginator.reduce(Actions.LoadPage(pageNumber: 2, id: ItemFlow.id).eraseToAnyAction())
        paginator.reduce(Actions.DidLoadItems(items: secondPageItems, id: ItemFlow.id).eraseToAnyAction())
        XCTAssertEqual(paginator.items.count, 20)
        XCTAssertEqual(paginator.page, .number(2))

        paginator.reduce(Actions.LoadPage(pageNumber: 3, id: ItemFlow.id).eraseToAnyAction())
        paginator.reduce(Actions.DidLoadItems(items: thirdPageItems, id: ItemFlow.id).eraseToAnyAction())
        XCTAssertEqual(paginator.items.count, 24)
        XCTAssertEqual(paginator.page, .lastPage(3))

        let firstPageItemPageNumber = try XCTUnwrap(paginator.pageNumber(for: firstPageItems.first!))
        XCTAssertEqual(firstPageItemPageNumber, 1)

        let secondPageItemPageNumber = try XCTUnwrap(paginator.pageNumber(for: secondPageItems.randomElement()!))
        XCTAssertEqual(secondPageItemPageNumber, 2)

        paginator.removeItems(after: 2)
        XCTAssertEqual(paginator.items.count, 20)

        paginator.removeItems(after: 1)
        XCTAssertEqual(paginator.items.count, 10)

        paginator.removeAllItems()
        XCTAssertTrue(paginator.items.isEmpty)
        XCTAssertEqual(paginator.page, .number(1))
    }

    func testPaginatorSetItems() {
        var paginator = Paginator<Item, ItemFlow.FlowId>(flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 24)

        paginator.set(items: items)
        XCTAssertEqual(paginator.items.count, 24)
        XCTAssertEqual(paginator.page.pageNumber, 3)
    }
}
