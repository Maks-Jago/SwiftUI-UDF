
//===--- FileFunctionLine.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A protocol to capture and store information about the file, function, and line number where an instance is created or used.
///
/// `FileFunctionLine` is useful for debugging purposes, as it provides metadata about the source location of an object.
/// Conforming to this protocol allows classes, structs, and other types to store and expose the file name, function name, and line number.
protocol FileFunctionLine {
    /// The name of the file where the instance was created.
    var fileName: String { get }
    
    /// The name of the function where the instance was created.
    var functionName: String { get }
    
    /// The line number in the source file where the instance was created.
    var lineNumber: Int { get }
}

/// A typealias representing a tuple containing file name, function name, and line number.
///
/// This is used to encapsulate metadata about a specific source location in the codebase.
typealias FileFunctionLineDescription = (fileName: String, functionName: String, lineNumber: Int)

/// A function that extracts or assigns file, function, and line number information for a given object.
///
/// This function is used to obtain the file, function, and line number details for an object that may or may not conform to `FileFunctionLine`.
/// If the object conforms to `FileFunctionLine`, it returns the values stored within the object. Otherwise, it returns the provided file, function, and line number.
///
/// - Parameters:
///   - object: The object to inspect, which may conform to `FileFunctionLine`.
///   - fileName: The file name where this function is called (default is the current file).
///   - functionName: The function name where this function is called (default is the current function).
///   - lineNumber: The line number where this function is called (default is the current line).
/// - Returns: A `FileFunctionLineDescription` tuple containing the file name, function name, and line number.
func fileFunctionLine<T>(
    _ object: T,
    fileName: String = #file,
    functionName: String = #function,
    lineNumber: Int = #line
) -> FileFunctionLineDescription {
    
    var fileName = fileName
    var functionName = functionName
    var lineNumber = lineNumber
    
    // Check if the object conforms to `FileFunctionLine` to extract the stored metadata.
    if let fileFunctionLine = object as? FileFunctionLine {
        fileName = fileFunctionLine.fileName
        functionName = fileFunctionLine.functionName
        lineNumber = fileFunctionLine.lineNumber
    }
    
    return (fileName, functionName, lineNumber)
}
