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
        // --- Swift Testing (Xcode 16+, Swift 6)
        if NSClassFromString("Testing.Test") != nil {
            return true
        }

        // --- XCTest (classic) signals present in the test host process
        if environment["XCTestConfigurationFilePath"] != nil { return true }
        if environment["XCTestBundlePath"] != nil { return true }
        if environment["XCInjectBundleInto"] != nil { return true } // unit tests injected into app host
        if environment["XCInjectBundle"] != nil { return true }

        if NSClassFromString("XCTestCase") != nil { return true }
        if Bundle.allBundles.contains(where: { $0.bundlePath.hasSuffix(".xctest") }) { return true }
        if Bundle.allFrameworks.contains(where: { $0.bundlePath.contains("/XCTest") }) { return true }

        // --- UI tests: the app-under-test is a separate process, so it won't have XCTest classes.
        // XCTest adds "-ui_testing" to launch arguments when running UI tests.
        // (Recommend adding it explicitly in your UITests: `app.launchArguments += ["-ui_testing"]`)
        if arguments.contains("-ui_testing") { return true }

        // --- SwiftPM/Linux runners sometimes set these
        if environment["SWIFTPM_TESTS"] != nil { return true }
        if environment["SWIFT_PACKAGE_TESTS"] != nil { return true }

        if environment["UNDER_TEST"] != nil { return true }
        return false
    }

    @available(*, deprecated, renamed: "isRunningTests", message: "use `isRunningTests` instead of xcTest")
    var xcTest: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
