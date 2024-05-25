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
        guard let group = self.value as? ActionGroup else {
            return [self]
        }

        return group._actions.flatMap { $0.unwrapActions() }
    }
}
