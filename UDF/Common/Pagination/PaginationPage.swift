//
//  PaginationPage.swift
//
//
//  Created by Max Kuznetsov on 27.01.2021.
//

import Foundation

public enum PaginationPage {
    case number(Int)
    case lastPage(Int)

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
        }
    }
}

extension PaginationPage: Equatable {}
