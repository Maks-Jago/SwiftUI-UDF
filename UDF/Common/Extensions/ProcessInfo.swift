//===--- ProcessInfo.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

public extension ProcessInfo {
    /// A computed property that checks if the current process is running within an XCTest environment.
    ///
    /// This property returns `true` if the process contains an environment variable `"XCTestConfigurationFilePath"`,
    /// indicating that the code is being executed in a test context.
    ///
    /// Example usage:
    /// ```
    /// if ProcessInfo.processInfo.xcTest {
    ///     // Perform test-specific logic
    /// }
    /// ```
    var xcTest: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
