//===--- UserInputDebouncer.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine
import Foundation

/// A utility class that debounces user input, emitting the latest value after a specified delay.
///
/// `UserInputDebouncer` is an `ObservableObject` that uses Combine to delay the emission of input values,
/// reducing the frequency of updates from rapid user input changes (e.g., typing in a text field).
///
/// - Note: The `debouncedValue` is updated only after the specified debounce time has passed since the last change to `value`.
///
/// - Parameters:
///   - T: The type of the value being debounced.
final class UserInputDebouncer<T>: ObservableObject {
    /// The debounced value that gets updated after the debounce delay.
    @Published var debouncedValue: T

    /// The value that the user is inputting. Updating this triggers the debouncing process.
    @Published var value: T

    private var cancelation: AnyCancellable!

    /// Initializes a new `UserInputDebouncer` with a default value and debounce delay.
    ///
    /// - Parameters:
    ///   - defaultValue: The initial value for both `value` and `debouncedValue`.
    ///   - debounceTime: The delay interval for debouncing, in seconds. Default is 0.1 seconds.
    init(defaultValue: T, debounceTime: TimeInterval = 0.1) {
        value = defaultValue
        debouncedValue = defaultValue

        cancelation = $value
            .debounce(for: .seconds(debounceTime), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                self?.debouncedValue = value
            }
    }
}
