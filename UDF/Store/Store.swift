//
//  BaseStore.swift
//  
//
//  Created by Max Kuznetsov on 05.10.2021.
//

import Foundation

public protocol Store<State>: Actor {
    associatedtype State: AppReducer

    var state: State { get }

    nonisolated func dispatch(_ action: some Action, priority: ActionPriority, fileName: String, functionName: String, lineNumber: Int)
}

public extension Store {
    nonisolated func dispatch(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        dispatch(action, priority: priority, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }

    func bind(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> Command {
        return {
            self.dispatch(
                action,
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }

    func bind<T>(
        _ action: @escaping (T) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith<T> {
        return { value in
            self.dispatch(
                action(value),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
}
