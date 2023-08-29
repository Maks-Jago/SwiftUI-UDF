//
//  Paginator.swift
//
//  Created by Max Kuznetsov on 27.01.2021.
//

import Foundation
import SwiftUI

public struct Paginator<Item: Hashable & Identifiable, FlowId: Hashable>: Reducible {

    public private(set) var items: OrderedSet<Item.ID> = []
    public private(set) var page: PaginationPage
    public var perPage: Int
    public var usePrefixForFirstPage: Bool
    public var initialPage: Int
    public var flowId: FlowId

    public private(set) var isLoading: Bool = false
    public var elements: [Item.ID] { items.elements }

    public var isLoadingInitialPage: Bool {
        page.pageNumber == initialPage && isLoading
    }

    public init(flowId: FlowId, perPage: Int, usePrefixForFirstPage: Bool = false, initialPage: Int = 1) {
        self.flowId = flowId
        self.perPage = perPage
        self.usePrefixForFirstPage = usePrefixForFirstPage
        self.initialPage = initialPage
        self.page = .number(initialPage)
    }

    public init() {
        fatalError("use init(flowId:perPage:usePrefixForFirstPage:initialPage:) insted of init")
    }

    public mutating func set(items: [Item.ID]) {
        self.items = .init(items)

        if let last = items.last, let pageNumber = self.pageNumber(for: last) {
            self.page = .number(pageNumber)
        } else {
            self.page = .number(initialPage)
            self.items.removeAll()
        }
    }

    public mutating func set(items: [Item]) {
        set(items: items.map(\.id))
    }

    public func pageNumber(for item: Item) -> Int? {
        pageNumber(for: item.id)
    }

    public func pageNumber(for itemId: Item.ID) -> Int? {
        guard let itemIndex = items.firstIndex(of: itemId) else {
            return nil
        }

        return (itemIndex / perPage) + initialPage
    }

    public mutating func removeItems(after page: Int) {
        guard self.page.pageNumber != page else {
            return
        }

        self.page = .number(page)

        let itemsToRemove = items.count - (page * perPage)
        items.removeLast(itemsToRemove)
    }

    public mutating func removeAllItems() {
        self.page = .number(initialPage)
        items.removeAll()
    }
    
    // move item in to reorder elements
    public mutating func moveItem(fromIndex: Int, toIndex: Int) {
        if toIndex <= items.count && toIndex >= 0 {
            items.elements.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)
        }
    }

    public mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidLoadItems<Item> where action.id == flowId:
            isLoading = false

            if case .number(let currentPage) = self.page, currentPage == initialPage {
                if action.items.isEmpty, usePrefixForFirstPage {
                    items = OrderedSet(Array(items.prefix(perPage)))
                } else {
                    items = .init(action.items.map(\.id))
                }
            } else {
                items.append(contentsOf: action.items.map(\.id))
            }

            if action.items.isEmpty || action.items.count < perPage {
                page = .lastPage(self.page.pageNumber)
            }

        case let action as Actions.LoadPage where action.id == flowId && action.pageNumber == initialPage:
            isLoading = true
            page = .number(initialPage)

        case let action as Actions.LoadPage where action.id == flowId:
            guard case .number = self.page else {
                return
            }

            // if action.pageNumber < self.page.pageNumber, it means that we need to refresh some page inside list of pages. To be sure in next sequence of pages consistency, we must remove all items after refreshable page.
            if action.pageNumber < self.page.pageNumber {
                removeItems(after: action.pageNumber)
            }

            isLoading = true
            page = .number(action.pageNumber)

        case let action as Actions.Error where action.id == flowId:
            if page.pageNumber > initialPage, isLoading {
                page = .number(page.pageNumber - 1)
            }

            isLoading = false

        case let action as Actions.SetPaginationItems<Item> where action.id == flowId:
            set(items: action.items)

        case let action as Actions.SetPaginationItems<Item.ID> where action.id == flowId:
            set(items: action.items)

        default:
            break
        }
    }
}

// MARK: - Codable
extension Paginator: Codable where Item.ID: Codable, FlowId: Codable {}
