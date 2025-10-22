//===--- ProcessInfo.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Testing

public extension ProcessInfo {
    /// A computed property that checks if the current process is running within a test environment.
    ///
    /// This property returns `true` if the process contains environment variables indicating
    /// that the code is being executed in a test context (either XCTest or Swift Testing).
    ///
    /// Example usage:
    /// ```
    /// if ProcessInfo.processInfo.isRunningTests {
    ///     // Perform test-specific logic
    /// }
    /// ```
    var isRunningTests: Bool {
        Test.current != nil ||
        environment["XCTestConfigurationFilePath"] != nil ||
        NSClassFromString("XCTestCase") != nil ||
        Bundle.allBundles.contains { $0.bundlePath.hasSuffix(".xctest") }
    }

    @available(*, deprecated, renamed: "isRunningTests", message: "use `isRunningTests` instead of xcTest")
    var xcTest: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
