//
//  Paginator.swift
//  
//
//  Created by Max Kuznetsov on 27.01.2021.
//

import Foundation

public struct Paginator<Item: Hashable & Identifiable, Flow: IdentifiableFlow>: Reducible where Flow.FlowId: Hashable {

    public var items: OrderedSet<Item.ID> = []
    public var page: PaginationPage = .number(1)
    public var perPage: Int
    public var usePrefixForFirstPage: Bool = true
    public var initialPage: Int = 1

    private var isLoading: Bool = false

    public init(perPage: Int, usePrefixForFirstPage: Bool = true, initialPage: Int = 1) {
        self.perPage = perPage
        self.usePrefixForFirstPage = usePrefixForFirstPage
        self.initialPage = initialPage
        self.page = .number(initialPage)
    }
    
    public init() {
        self.perPage = 25
        self.usePrefixForFirstPage = true
    }
    
    public mutating func reduce(_ action: AnyAction) {
        switch action.value {
        case let action as AnyAction.DidLoadItems<Item> where action.id == Flow.id:
            isLoading = false

            if case .number(let currentPage) = self.page, currentPage == initialPage {
                if action.items.isEmpty, usePrefixForFirstPage {
                    items = OrderedSet(Array(items.prefix(perPage)))
                } else {
                    items = .init(action.items.map(\.id))
                }
            } else {
                items.append(action.items.map(\.id))
            }
            
            if action.items.isEmpty || action.items.count < perPage {
                page = .lastPage(self.page.pageNumber)
            }
            
        case let action as AnyAction.LoadPage where action.id == Flow.id && action.pageNumber == initialPage:
            isLoading = true
            page = .number(initialPage)
            
        case let action as AnyAction.LoadPage where action.id == Flow.id:
            guard case .number = self.page else {
                return
            }

            isLoading = true
            page = .number(action.pageNumber)

        case let action as AnyAction.Error where action.id == Flow.id:
            if page.pageNumber > initialPage, isLoading {
                page = .number(page.pageNumber - 1)
            }

            isLoading = false

        default:
            break
        }
    }
}

// MARK: - Codable
extension Paginator: Codable where Item.ID: Codable {}


extension PaginationPage: Codable {
    enum CodingKeys: String, CodingKey {
        case number, lastPage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let pageNumber = try container.decodeIfPresent(Int.self, forKey: .number) {
            self = .number(pageNumber)
        } else if let pageNumber = try container.decodeIfPresent(Int.self, forKey: .lastPage) {
            self = .lastPage(pageNumber)
        } else {
            self = .number(1)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .number(let pageNumber):
            try container.encode(pageNumber, forKey: .number)

        case .lastPage(let pageNumber):
            try container.encode(pageNumber, forKey: .lastPage)
        @unknown default:
            fatalError()
        }
    }
}
