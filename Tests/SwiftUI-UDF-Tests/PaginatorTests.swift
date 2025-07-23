//
//  PaginatorTests.swift
//
//
//  Created by Max Kuznetsov on 15.09.2021.
//

@testable import UDF
import Testing

@Suite 
struct PaginatorTests {
    struct Item: Identifiable, Hashable, Codable {
        struct Id: Hashable, Codable {
            var value: Int
        }

        var id: Id
        var title: String
        var text: String

        init() {
            id = .init(value: .random(in: 0 ..< Int.max))
            title = "title \(id.value)"
            text = "text \(id.value)"
        }

        static func fakeItems(count: Int) -> [Item] {
            (0 ..< count).map { _ in Self() }
        }
    }

    enum ItemFlow: IdentifiableFlow {
        case none

        init() { self = .none }

        mutating func reduce(_ action: some Action) {}
    }

    struct AppState: AppReducer, Equatable {
        var itemsForm = ItemsForm()
    }

    struct ItemsForm: Form, Codable {
        var paginator: Paginator = .init(Item.self, flowId: ItemFlow.id, perPage: 10)
    }

    @Test func paginatorPagesRemoving() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let firstPageItems = Item.fakeItems(count: 10)
        let secondPageItems = Item.fakeItems(count: 10)
        let thirdPageItems = Item.fakeItems(count: 4)

        paginator.reduce(Actions.LoadPage(id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: firstPageItems, id: ItemFlow.id))
        #expect(paginator.items.count == 10)
        #expect(paginator.page == .number(1))

        paginator.reduce(Actions.LoadPage(pageNumber: 2, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: secondPageItems, id: ItemFlow.id))
        #expect(paginator.items.count == 20)
        #expect(paginator.page == .number(2))

        paginator.reduce(Actions.LoadPage(pageNumber: 3, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: thirdPageItems, id: ItemFlow.id))
        #expect(paginator.items.count == 24)
        #expect(paginator.page == .lastPage(3))

        let firstPageItemPageNumber = try #require(paginator.pageNumber(for: firstPageItems.first!))
        #expect(firstPageItemPageNumber == 1)

        let secondPageItemPageNumber = try #require(paginator.pageNumber(for: secondPageItems.randomElement()!))
        #expect(secondPageItemPageNumber == 2)

        paginator.removeItems(after: 2)
        #expect(paginator.items.count == 20)

        paginator.removeItems(after: 1)
        #expect(paginator.items.count == 10)

        paginator.removeAllItems()
        #expect(paginator.items.isEmpty)
        #expect(paginator.page == .number(1))
    }

    @Test func paginatorSetItems() {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 24)

        paginator.set(items: items)
        #expect(paginator.items.count == 24)
        #expect(paginator.page.pageNumber == 3)
    }

    @Test func paginatorSetItemsAction() {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 24)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))
        #expect(paginator.items.count == 24)
        #expect(paginator.page.pageNumber == 3)

        paginator.removeAllItems()
        paginator.reduce(Actions.SetPaginationItems<Item.Id>(items: items.map(\.id), id: ItemFlow.id))
        #expect(paginator.items.count == 24)
        #expect(paginator.page.pageNumber == 3)
    }

    @Test func paginatorLoadingMiddlePage() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 44)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))
        #expect(paginator.page.pageNumber == 5)

        paginator.reduce(Actions.LoadPage(pageNumber: 2, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: Item.fakeItems(count: 10), id: ItemFlow.id))

        #expect(paginator.page.pageNumber == 2)
        #expect(paginator.items.count == 30)
    }

    @Test func paginatorLoadingFirstPage() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 44)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))
        #expect(paginator.page.pageNumber == 5)

        paginator.reduce(Actions.LoadPage(pageNumber: 1, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: Item.fakeItems(count: 10), id: ItemFlow.id))

        #expect(paginator.page.pageNumber == 1)
        #expect(paginator.items.count == 10)
    }

    @Test func paginatorLoading() async {
        let store = await TestStore(initial: AppState())
        await store.dispatch(Actions.LoadPage(id: ItemFlow.id))

        let isLoading = await store.state.itemsForm.paginator.isLoading
        #expect(isLoading == true)

        await store.dispatch(Actions.DidLoadItems(items: Item.fakeItems(count: 10), id: ItemFlow.id))

        let pageNumber = await store.state.itemsForm.paginator.page.pageNumber
        #expect(pageNumber == 1)

        let itemsCount = await store.state.itemsForm.paginator.items.count
        #expect(itemsCount == 10)
    }

    @Test func moveItem() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 14)
        let firstItem = try #require(items.first)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))

        let isSuccess = paginator.moveItem(fromIndex: 0, toIndex: 13)
        #expect(isSuccess)
        let lastItemId = try #require(paginator.items.last)
        #expect(firstItem.id == lastItemId)

        let isFailure = paginator.moveItem(fromIndex: 0, toIndex: 14) // toIndex >= items.count
        #expect(!isFailure)

        let itemAt10Index = try #require(paginator.elements[10])
        let isMovedIntoBeginning = paginator.moveItem(fromIndex: 10, toIndex: 0)
        #expect(isMovedIntoBeginning)
        let firstItemId = try #require(paginator.items.first)
        #expect(itemAt10Index == firstItemId)
    }

    @Test func moveItemInvalidIndices() {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 5)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))

        let negativeResult = paginator.moveItem(fromIndex: -1, toIndex: 0)
        #expect(!negativeResult)

        let outOfBoundsResult = paginator.moveItem(fromIndex: items.count, toIndex: 0)
        #expect(!outOfBoundsResult)
    }
}
