//===--- Text+Mirror.swift -------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

extension FormatStyle {
    /// Attempts to format a given value using the format style.
    ///
    /// - Parameter value: The value to format. Must be of a type that conforms to `FormatInput`.
    /// - Returns: The formatted output if successful, or `nil` if the input type is not supported.
    func format(any value: Any) -> FormatOutput? {
        if let v = value as? FormatInput {
            return format(v)
        }
        return nil
    }
}

extension LocalizedStringKey {
    /// Resolves a `LocalizedStringKey` to its formatted string representation.
    ///
    /// - Returns: A `String` representing the localized key with any format arguments, or `nil` if resolution fails.
    var resolved: String? {
        let mirror = Mirror(reflecting: self)
        
        // Extracts the key from the mirrored object
        guard let key = mirror.descendant("key") as? String else {
            return nil
        }
        
        // Extracts the arguments used in the localized string
        guard let args = mirror.descendant("arguments") as? [Any] else {
            return nil
        }
        
        // Processes the arguments for formatting
        let values = args.map { arg -> Any? in
            let mirror = Mirror(reflecting: arg)
            if let value = mirror.descendant("storage", "value", ".0") {
                return value
            }
            
            guard let format = mirror.descendant("storage", "formatStyleValue", "format") as? any FormatStyle,
                  let input = mirror.descendant("storage", "formatStyleValue", "input") else {
                return nil
            }
            
            return format.format(any: input)
        }
        
        // Converts the values to CVarArg to use with String formatting
        let va = values.compactMap { arg -> CVarArg? in
            switch arg {
            case let i as Int:      return i
            case let i as Int64:    return i
            case let i as Int8:     return i
            case let i as Int16:    return i
            case let i as Int32:    return i
            case let u as UInt:     return u
            case let u as UInt64:   return u
            case let u as UInt8:    return u
            case let u as UInt16:   return u
            case let u as UInt32:   return u
            case let f as Float:    return f
            case let f as CGFloat:  return f
            case let d as Double:   return d
            case let o as NSObject: return o
            default:                return nil
            }
        }
        
        if va.count != values.count {
            return nil
        }
        
        return String.localizedStringWithFormat(key, va)
    }
}

extension Text {
    /// Extracts the content of the `Text` view as a `String`.
    ///
    /// This method attempts to access the various storage properties of the `Text` view to retrieve
    /// the underlying string, whether it's a verbatim string, an attributed string, or a localized string key.
    ///
    /// - Returns: A `String` representing the content of the `Text` view, or `nil` if extraction fails.
    var content: String? {
        let mirror = Mirror(reflecting: self)
        
        // Attempts to extract a verbatim string
        if let s = mirror.descendant("storage", "verbatim") as? String {
            return s
        }
        // Attempts to extract an attributed string
        else if let attrStr = mirror.descendant("storage", "anyTextStorage", "str") as? AttributedString {
            return String(attrStr.characters)
        }
        // Attempts to extract a localized string key
        else if let key = mirror.descendant("storage", "anyTextStorage", "key") as? LocalizedStringKey {
            return key.resolved
        }
        // Attempts to use a format style to extract the string
        else if let format = mirror.descendant("storage", "anyTextStorage", "storage", "format") as? any FormatStyle,
                let input = mirror.descendant("storage", "anyTextStorage", "storage", "input") {
            return format.format(any: input) as? String
        }
        // Attempts to use a formatter to extract the string
        else if let formatter = mirror.descendant("storage", "anyTextStorage", "formatter") as? Formatter,
                let object = mirror.descendant("storage", "anyTextStorage", "object") {
            return formatter.string(for: object)
        }
        return nil
    }
}
