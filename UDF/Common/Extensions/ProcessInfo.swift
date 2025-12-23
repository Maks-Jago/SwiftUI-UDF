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
        if environment["UNDER_TEST"] != nil { return true }
        if environment["CI"] != nil { return true }
        if environment["XCTestConfigurationFilePath"] != nil { return true }
        if environment["XCTestBundlePath"] != nil { return true }
        if environment["XCInjectBundleInto"] != nil { return true }
        if environment["XCInjectBundle"] != nil { return true }
        if environment["SWIFTPM_TESTS"] != nil { return true }
        if environment["SWIFT_PACKAGE_TESTS"] != nil { return true }
        if arguments.contains("-ui_testing") { return true }
        return false
    }

    @available(*, deprecated, renamed: "isRunningTests", message: "use `isRunningTests` instead of xcTest")
    var xcTest: Bool {
        isRunningTests
    }
}
