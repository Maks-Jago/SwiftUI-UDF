//===--- Paginator.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A `Paginator` structure that manages a list of paginated items.
/// Supports loading, appending, removing, and reordering of items, while also keeping track of the current page and loading state.
public struct Paginator<Item: Hashable & Identifiable, FlowId: Hashable>: Reducible {
    
    /// The ordered set of item IDs.
    public private(set) var items: OrderedSet<Item.ID> = []
    
    /// The current page of the pagination.
    public private(set) var page: PaginationPage
    
    /// The number of items per page.
    public var perPage: Int
    
    /// A flag to indicate whether to use a prefix for the first page.
    public var usePrefixForFirstPage: Bool
    
    /// The initial page number.
    public var initialPage: Int
    
    /// The ID of the flow that this paginator belongs to.
    public var flowId: FlowId
    
    /// A flag indicating whether a page is currently loading.
    public private(set) var isLoading: Bool = false
    
    /// The array of item IDs in the paginator.
    public var elements: [Item.ID] { items.elements }
    
    /// A flag indicating whether the paginator is loading the initial page.
    public var isLoadingInitialPage: Bool {
        page.pageNumber == initialPage && isLoading
    }
    
    /// Initializes the paginator with the specified item type, flow ID, items per page, and other options.
    /// - Parameters:
    ///   - itemType: The type of the items.
    ///   - flowId: The flow ID associated with this paginator.
    ///   - perPage: The number of items per page.
    ///   - usePrefixForFirstPage: Indicates whether to use a prefix for the first page.
    ///   - initialPage: The initial page number.
    public init(_ itemType: Item.Type, flowId: FlowId, perPage: Int, usePrefixForFirstPage: Bool = false, initialPage: Int = 1) {
        self.flowId = flowId
        self.perPage = perPage
        self.usePrefixForFirstPage = usePrefixForFirstPage
        self.initialPage = initialPage
        self.page = .number(initialPage)
    }
    
    /// Disallowed initializer to prevent improper usage.
    public init() {
        fatalError("use init(flowId:perPage:usePrefixForFirstPage:initialPage:) instead of init")
    }
    
    /// Sets the paginator's items.
    /// - Parameter items: An array of item IDs to set in the paginator.
    public mutating func set(items: [Item.ID]) {
        self.items = .init(items)
        
        if let last = items.last, let pageNumber = self.pageNumber(for: last) {
            self.page = .number(pageNumber)
        } else {
            self.page = .number(initialPage)
            self.items.removeAll()
        }
    }
    
    /// Sets the paginator's items using an array of items.
    /// - Parameter items: An array of items to set in the paginator.
    public mutating func set(items: [Item]) {
        set(items: items.map(\.id))
    }
    
    /// Gets the page number for the specified item.
    /// - Parameter item: The item to get the page number for.
    /// - Returns: The page number for the item, or `nil` if not found.
    public func pageNumber(for item: Item) -> Int? {
        pageNumber(for: item.id)
    }
    
    /// Gets the page number for the specified item ID.
    /// - Parameter itemId: The ID of the item to get the page number for.
    /// - Returns: The page number for the item, or `nil` if not found.
    public func pageNumber(for itemId: Item.ID) -> Int? {
        guard let itemIndex = items.firstIndex(of: itemId) else {
            return nil
        }
        return (itemIndex / perPage) + initialPage
    }
    
    /// Removes items after the specified page.
    /// - Parameter page: The page number to remove items after.
    public mutating func removeItems(after page: Int) {
        guard self.page.pageNumber != page else {
            return
        }
        
        self.page = .number(page)
        let itemsToRemove = items.count - (page * perPage)
        items.removeLast(itemsToRemove)
    }
    
    /// Removes all items from the paginator.
    public mutating func removeAllItems() {
        self.page = .number(initialPage)
        items.removeAll()
    }
    
    /// Moves an item within the paginator.
    /// - Parameters:
    ///   - fromIndex: The index of the item to move.
    ///   - toIndex: The destination index to move the item to.
    /// - Returns: A Boolean value indicating whether the item was successfully moved.
    @discardableResult
    public mutating func moveItem(fromIndex: Int, toIndex: Int) -> Bool {
        guard toIndex < items.count && toIndex >= 0, items.count > 0 else {
            return false
        }
        let item = items.elements[fromIndex]
        items.elements.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? (toIndex + 1) : toIndex)
        return item == items.elements[toIndex]
    }
    
    /// Reduces the paginator's state based on the provided action.
    /// - Parameter action: The action to reduce the state with.
    public mutating func reduce(_ action: some Action) {
        switch action {
            
            // Handle `DidLoadItems` action
        case let action as Actions.DidLoadItems<Item> where action.id == flowId:
            isLoading = false  // Stop the loading state since items have been loaded
            
            // Check if the paginator is on the initial page
            if case .number(let currentPage) = self.page, currentPage == initialPage {
                
                // If the loaded items are empty and `usePrefixForFirstPage` is true, retain only the first `perPage` items
                if action.items.isEmpty, usePrefixForFirstPage {
                    items = OrderedSet(Array(items.prefix(perPage)))
                } else {
                    // Set the paginator's items to the newly loaded items
                    items = .init(action.items.map(\.id))
                }
            } else {
                // If not on the initial page, append the new items to the existing list
                items.append(contentsOf: action.items.map(\.id))
            }
            
            // Check if the loaded items are fewer than `perPage`, indicating that there are no more pages to load
            if action.items.isEmpty || action.items.count < perPage {
                page = .lastPage(self.page.pageNumber)
            }
            
            // Handle `LoadPage` action for the initial page
        case let action as Actions.LoadPage where action.id == flowId && action.pageNumber == initialPage:
            isLoading = true  // Start loading state
            page = .number(initialPage)  // Reset the page to the initial page number
            
            // Handle `LoadPage` action for subsequent pages
        case let action as Actions.LoadPage where action.id == flowId:
            guard case .number = self.page else {
                return  // Do nothing if the current page is not a numeric page
            }
            
            // If the new page number is less than the current page, remove items after the new page to ensure consistency
            if action.pageNumber < self.page.pageNumber {
                removeItems(after: action.pageNumber)
            }
            
            isLoading = true  // Start loading state
            page = .number(action.pageNumber)  // Set the current page to the new page number
            
            // Handle `Error` action
        case let action as Actions.Error where action.id == flowId:
            // If an error occurs while loading a page beyond the initial page, revert to the previous page number
            if page.pageNumber > initialPage, isLoading {
                page = .number(page.pageNumber - 1)
            }
            
            isLoading = false  // Stop the loading state
            
            // Handle `SetPaginationItems` action with an array of items
        case let action as Actions.SetPaginationItems<Item> where action.id == flowId:
            set(items: action.items)  // Set the paginator's items to the provided array
            
            // Handle `SetPaginationItems` action with an array of item IDs
        case let action as Actions.SetPaginationItems<Item.ID> where action.id == flowId:
            set(items: action.items)  // Set the paginator's items to the provided array of IDs
            
            // Default case for unhandled actions
        default:
            break
        }
    }
}

// MARK: - Codable
extension Paginator: Codable where Item.ID: Codable, FlowId: Codable {}
