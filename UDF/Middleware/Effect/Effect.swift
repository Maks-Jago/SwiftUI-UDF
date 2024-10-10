//===--- Effect.swift --------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Combine

/// A concrete implementation of `Effectable` that produces actions as a result of various publishers.
///
/// `Effect` wraps a `Combine` publisher and transforms its output into actions to be dispatched in the UDF architecture.
/// It provides several initializers to handle different types of publishers, converting their outputs and errors into
/// specific actions. Additionally, it includes metadata for debugging purposes, such as file name, function name, and line number.
///
/// ## Example
/// ```swift
/// let effect = Effect(
///     Just("Sample Data").setFailureType(to: Error.self),
///     id: "sample_id",
///     mapper: { output in Actions.SampleAction(data: output) }
/// )
///
/// let simpleEffect = Effect(action: Actions.SomeAction())
/// ```
///
/// This example demonstrates how to create an `Effect` that emits actions based on publisher output or directly from an action.
public struct Effect: Effectable, FileFunctionLine {
    
    // The underlying publisher that produces actions.
    public var upstream: AnyPublisher<any Action, Never>
    
    // Metadata for debugging: file name, function name, and line number.
    var fileName: String
    var functionName: String
    var lineNumber: Int
    
    // MARK: - Initializers
    
    /// Creates an `Effect` from a publisher that outputs items of type `P.Output` and converts them into actions.
    ///
    /// - Parameters:
    ///   - publisher: The publisher that produces the output.
    ///   - id: A unique identifier for the effect.
    ///   - fileName: The file name for debugging purposes (defaults to the current file).
    ///   - functionName: The function name for debugging purposes (defaults to the current function).
    ///   - lineNumber: The line number for debugging purposes (defaults to the current line).
    ///   - mapper: A closure that maps the publisher's output to an action.
    public init<P: Publisher, A: Action, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        mapper: @escaping (P.Output) -> A
    ) where A: Equatable, P.Failure == Error {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        
        self.upstream = Deferred { publisher }
            .map { mapper($0) }
            .catch { Just(Actions.Error(error: $0.localizedDescription, id: id)) }
            .eraseToAnyPublisher()
    }
    
    /// Creates an `Effect` from a publisher that outputs a single item and wraps it into a `DidLoadItem` action.
    ///
    /// - Parameters:
    ///   - publisher: The publisher that produces the output.
    ///   - id: A unique identifier for the effect.
    ///   - fileName: The file name for debugging purposes (defaults to the current file).
    ///   - functionName: The function name for debugging purposes (defaults to the current function).
    ///   - lineNumber: The line number for debugging purposes (defaults to the current line).
    ///   - mapper: A closure that maps the publisher's output to an action.
    public init<P: Publisher, A: Equatable, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        mapper: @escaping (P.Output) -> A
    ) where P.Failure == Error {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        
        self.upstream = Deferred { publisher }
            .map { Actions.DidLoadItem(item: mapper($0), id: id) }
            .catch { Just(Actions.Error(error: $0.localizedDescription, id: id)) }
            .eraseToAnyPublisher()
    }
    
    /// Creates an `Effect` from a publisher that outputs an array of items and wraps them into a `DidLoadItems` action.
    ///
    /// - Parameters:
    ///   - publisher: The publisher that produces an array of items.
    ///   - id: A unique identifier for the effect.
    ///   - fileName: The file name for debugging purposes (defaults to the current file).
    ///   - functionName: The function name for debugging purposes (defaults to the current function).
    ///   - lineNumber: The line number for debugging purposes (defaults to the current line).
    public init<P: Publisher, Item: Equatable, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where P.Failure == Error, P.Output == Array<Item> {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        
        self.upstream = Deferred { publisher }
            .map { Actions.DidLoadItems(items: $0, id: id) }
            .catch { Just(Actions.Error(error: $0.localizedDescription, id: id)) }
            .eraseToAnyPublisher()
    }
    
    /// Creates an `Effect` from a publisher that outputs an array of items and maps each item to a new type, wrapping them into a `DidLoadItems` action.
    ///
    /// - Parameters:
    ///   - publisher: The publisher that produces an array of items.
    ///   - id: A unique identifier for the effect.
    ///   - fileName: The file name for debugging purposes (defaults to the current file).
    ///   - functionName: The function name for debugging purposes (defaults to the current function).
    ///   - lineNumber: The line number for debugging purposes (defaults to the current line).
    ///   - mapItem: A closure that maps each item to a new type.
    public init<P: Publisher, Item, Id: Hashable, EqItem: Equatable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        mapItem: @escaping (Item) -> EqItem
    ) where P.Failure == Error, P.Output == Array<Item> {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        
        self.upstream = Deferred { publisher }
            .map { Actions.DidLoadItems<EqItem>(items: $0.map(mapItem), id: id) }
            .catch { Just(Actions.Error(error: $0.localizedDescription, id: id)) }
            .eraseToAnyPublisher()
    }
    
    /// Creates an `Effect` from a publisher that outputs a single item, wrapping it into a `DidLoadItem` action.
    ///
    /// - Parameters:
    ///   - publisher: The publisher that produces a single item.
    ///   - id: A unique identifier for the effect.
    ///   - fileName: The file name for debugging purposes (defaults to the current file).
    ///   - functionName: The function name for debugging purposes (defaults to the current function).
    ///   - lineNumber: The line number for debugging purposes (defaults to the current line).
    public init<P: Publisher, Item: Equatable, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where P.Failure == Error, P.Output == Item {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        
        self.upstream = Deferred { publisher }
            .map { Actions.DidLoadItem(item: $0, id: id) }
            .catch { Just(Actions.Error(error: $0.localizedDescription, id: id)) }
            .eraseToAnyPublisher()
    }
    
    /// Creates an `Effect` that directly emits a specified action.
    ///
    /// - Parameters:
    ///   - action: The action to be produced by this effect.
    ///   - fileName: The file name for debugging purposes (defaults to the current file).
    ///   - functionName: The function name for debugging purposes (defaults to the current function).
    ///   - lineNumber: The line number for debugging purposes (defaults to the current line).
    public init(
        action: Output,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
        
        self.upstream = Deferred {
            Just(action)
        }
        .eraseToAnyPublisher()
    }
    
    /// Creates an `Effect` using a closure that returns an action.
    ///
    /// - Parameters:
    ///   - fileName: The file name for debugging purposes (defaults to the current file).
    ///   - functionName: The function name for debugging purposes (defaults to the current function).
    ///   - lineNumber: The line number for debugging purposes (defaults to the current line).
    ///   - future: A closure that returns an action to be produced by this effect.
    public init(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        _ future: @escaping () -> any Action
    ) {
        self.init(
            action: future(),
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }
}
