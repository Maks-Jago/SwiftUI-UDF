
import Foundation
import SwiftUI

extension FormatStyle {
    func format(any value: Any) -> FormatOutput? {
        if let v = value as? FormatInput {
            return format(v)
        }
        return nil
    }
}

extension LocalizedStringKey {
    var resolved: String? {
        let mirror = Mirror(reflecting: self)
        guard let key = mirror.descendant("key") as? String else {
            return nil
        }

        guard let args = mirror.descendant("arguments") as? [Any] else {
            return nil
        }

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
    var content: String? {
        let mirror = Mirror(reflecting: self)
        if let s = mirror.descendant("storage", "verbatim") as? String {
            return s
        } else if let attrStr = mirror.descendant("storage", "anyTextStorage", "str") as? AttributedString {
            return String(attrStr.characters)
        } else if let key = mirror.descendant("storage", "anyTextStorage", "key") as? LocalizedStringKey {
            return key.resolved
        } else if let format = mirror.descendant("storage", "anyTextStorage", "storage", "format") as? any FormatStyle,
                  let input = mirror.descendant("storage", "anyTextStorage", "storage", "input") {
            return format.format(any: input) as? String
        } else if let formatter = mirror.descendant("storage", "anyTextStorage", "formatter") as? Formatter,
                  let object = mirror.descendant("storage", "anyTextStorage", "object") {
            return formatter.string(for: object)
        }
        return nil
    }
}
