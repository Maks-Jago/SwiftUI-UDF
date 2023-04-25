
import Foundation

protocol FileFunctionLine {
    var fileName: String { get }
    var functionName: String { get }
    var lineNumber: Int { get }
}

typealias FileFunctionLineDescription = (fileName: String, functionName: String, lineNumber: Int)

func fileFunctionLine<T>(
    _ object: T,
    fileName: String = #file,
    functionName: String = #function,
    lineNumber: Int = #line
) -> FileFunctionLineDescription {

    var fileName = fileName
    var functionName = functionName
    var lineNumber = lineNumber

    if let fileFunctionLine = object as? FileFunctionLine {
        fileName = fileFunctionLine.fileName
        functionName = fileFunctionLine.functionName
        lineNumber = fileFunctionLine.lineNumber
    }

    return (fileName, functionName, lineNumber)
}
