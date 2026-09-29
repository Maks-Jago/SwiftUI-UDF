import Foundation
import SwiftUI
import Limn

struct InternalAction: Action {
    let value: any Action
    let fileName: String
    let functionName: String
    let lineNumber: Int

    var animation: Animation?
    var silent: Bool
    var delay: Delay?
    let createdAt: Date
    
    private var debugDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }

    private let actionMetadataDescription: String

    init(
        _ value: any Action,
        animation: Animation? = nil,
        silent: Bool = false,
        delay: Delay? = nil,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        self.value = value
        self.animation = animation
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        self.silent = silent
        self.delay = delay
        self.createdAt = .now
        
        let fileURL = NSURL(fileURLWithPath: fileName).lastPathComponent ?? "Unknown file"
        
        if let animation {
            actionMetadataDescription =
                "animation: \(String(describing: animation)) from \(fileURL) - \(functionName) at line \(lineNumber)"
        } else {
            actionMetadataDescription = "from \(fileURL) - \(functionName) at line \(lineNumber)"
        }
    }
}

// MARK: - Equatable
extension InternalAction: Equatable {
    public static func == (lhs: InternalAction, rhs: InternalAction) -> Bool {
        areEqual(lhs.value, rhs.value)
    }
}

// MARK: - CustomDebugStringConvertible
extension InternalAction: CustomDebugStringConvertible {
    public var debugDescription: String {
        var dumpFormat = Limn.DumpFormat(maxItems: 5, collectionIndexMinItems: 0)
        let allOptionalTypeNameComponents: UInt = 0b111
        let typeNameComponents = OptionalTypeNameComponents(rawValue: allOptionalTypeNameComponents)
        dumpFormat.typeNameComponents = typeNameComponents
        dumpFormat.symbols.collectionIndex = "[%d]"
        let actionDump = Limn(of: value)
            .stringDump(format: dumpFormat)
            .replacingOccurrences(of: #"\n+$"#, with: "", options: .regularExpression)
        
        return "[\(debugDateFormatter.string(from: createdAt))] \(actionDump), \(actionMetadataDescription)\n"
    }
}

// MARK: - ActionGroup
extension InternalAction {
    func unwrapActions(isIncluded: ((_ action: InternalAction) -> Bool) = { _ in true }) -> [InternalAction] {
        var result: [InternalAction] = []
        var stack = [self]

        while !stack.isEmpty {
            let current = stack.removeLast()

            switch current.value {
            case let bindableAction as any _AnyBindableAction:
                // Add the bindable action
                if !result.contains(where: { areEqual($0.value, current.value) }) {
                    result.append(current)
                }

                // Create and add the unwrapped action
                let unwrapped = InternalAction(
                    bindableAction.value,
                    animation: current.animation,
                    silent: current.silent,
                    fileName: current.fileName,
                    functionName: current.functionName,
                    lineNumber: current.lineNumber
                )

                if !result.contains(where: { areEqual($0.value, unwrapped.value) }) {
                    result.append(unwrapped)
                }

            case let actionGroup as ActionGroup:
                // Add all actions from the group to the stack
                stack.append(contentsOf: actionGroup._actions)

            default:
                if !result.contains(where: { areEqual($0.value, current.value) }) {
                    result.append(current)
                }
            }
        }

        return result.filter(isIncluded)
    }

    func findDelayedActions() -> [InternalAction] {
        self.unwrapActions().filter { $0.delay != nil }
    }
}
