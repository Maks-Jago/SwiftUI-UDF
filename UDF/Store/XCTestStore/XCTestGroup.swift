
import Foundation

public final class XCTestGroup {
    private static var shared = XCTestGroup()
    private lazy var group = DispatchGroup()
    private lazy var groupQueue = DispatchQueue(label: "XCTestGroup")

    public static func enter(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            shared.groupQueue.sync {
                shared.group.enter()
            }
        }
    }

    public static func leave(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            shared.groupQueue.sync {
                shared.group.leave()
            }
        }
    }

    public static func wait(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            _ = shared.group.wait(timeout: .now() + 4)
        }
    }
}
