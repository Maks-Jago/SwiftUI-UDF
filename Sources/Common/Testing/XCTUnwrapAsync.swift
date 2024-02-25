//
//  XCTUnwrapAsync.swift
//  
//
//  Created by Arthur Zavolovych on 13.02.2024.
//

#if canImport(XCTest)
import XCTest

public func XCTUnwrapAsync<T>(_ expression: @autoclosure () async throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async throws -> T {
    let res = try await expression()
    return try XCTUnwrap(res, message(), file: file, line: line)
}
#endif
