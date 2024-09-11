import Foundation
import SwiftUI

struct InternalAction: @unchecked Sendable, Action {
    let value: any Action
    let fileName: String
    let functionName: String
    let lineNumber: Int

    var animation: Animation?
    var silent: Bool

    private let actionDescription: String
    
    init(_ value: some Action, animation: Animation? = nil, silent: Bool = false, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        self.value = value
        self.animation = animation
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        self.silent = silent

        let fileURL = NSURL(fileURLWithPath: fileName).lastPathComponent ?? "Unknown file"
        if let animation {
            actionDescription = "\(String(describing: value)), animation: \(String(describing: animation)) from \(fileURL) - \(functionName) at line \(lineNumber)"
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
    
    func unwrapActions() -> [InternalAction] {
        func actions(from internalAction: InternalAction) -> [InternalAction] {
            var actions: [InternalAction] = []
            switch self.value {
            case let action as any _AnyBindableAction:
                actions.append(internalAction)
                actions.append(
                    InternalAction(
                        action.value,
                        animation: self.animation,
                        silent: self.silent,
                        fileName: self.fileName,
                        functionName: self.functionName,
                        lineNumber: self.lineNumber
                    )
                )

            case let group as ActionGroup:
                actions.append(contentsOf: group._actions.flatMap { $0.unwrapActions() })

            default:
                actions.append(internalAction)
            }

            return actions
        }

        return actions(from: self)
    }
}
