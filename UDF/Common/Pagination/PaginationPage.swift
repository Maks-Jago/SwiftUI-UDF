//
//  PaginationPage.swift
//
//
//  Created by Max Kuznetsov on 27.01.2021.
//

import Foundation

/// `PaginationPage` is an enumeration that represents the current page in a pagination process. It has two cases:
/// - `number(Int)`: Represents a regular page number.
/// - `lastPage(Int)`: Represents the last page in the pagination process.
public enum PaginationPage {
    case number(Int)
    case lastPage(Int)
    
    /// Returns the page number associated with the current case, whether it's a regular page or the last page.
    public var pageNumber: Int {
        switch self {
        case .number(let page),
                .lastPage(let page):
            return page
        }
    }
}

extension PaginationPage: Codable {
    enum CodingKeys: String, CodingKey {
        case number, lastPage
    }
    
    /// Decodes a `PaginationPage` from a JSON representation.
    /// The initializer attempts to decode the page number from the given decoder.
    /// It first looks for the `number` key; if not found, it attempts to find the `lastPage` key.
    /// If neither is found, it defaults to `.number(1)`.
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
    
    /// Encodes a `PaginationPage` into a JSON representation.
    /// Depending on whether the page is a regular page or the last page, it encodes the associated page number using the appropriate key.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .number(let pageNumber):
            try container.encode(pageNumber, forKey: .number)
            
        case .lastPage(let pageNumber):
            try container.encode(pageNumber, forKey: .lastPage)
        }
    }
}

extension PaginationPage: Equatable {}
