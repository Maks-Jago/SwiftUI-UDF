import Foundation
import SwiftUI

struct InternalAction: Action {
    let value: any Action
    let fileName: String
    let functionName: String
    let lineNumber: Int

    var animation: Animation?
    var silent: Bool
    var delay: Delay?

    private let actionDescription: String

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

        let fileURL = NSURL(fileURLWithPath: fileName).lastPathComponent ?? "Unknown file"
        if let animation {
            actionDescription =
                "\(String(describing: value)), animation: \(String(describing: animation)) from \(fileURL) - \(functionName) at line \(lineNumber)"
        } else {
            actionDescription = "\(String(describing: value)) from \(fileURL) - \(functionName) at line \(lineNumber)"
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
        actionDescription
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
