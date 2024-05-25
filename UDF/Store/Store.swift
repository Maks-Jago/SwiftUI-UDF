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

    func bind<T1, T2>(
        _ action: @escaping (T1, T2) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith2<T1, T2> {
        return { v1, v2 in
            self.dispatch(
                action(v1, v2),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }

    func bind<T1, T2, T3>(
        _ action: @escaping (T1, T2, T3) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith3<T1, T2, T3> {
        return { v1, v2, v3 in
            self.dispatch(
                action(v1, v2, v3),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }

    func bind<T1, T2, T3, T4>(
        _ action: @escaping (T1, T2, T3, T4) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith4<T1, T2, T3, T4> {
        return { v1, v2, v3, v4 in
            self.dispatch(
                action(v1, v2, v3, v4),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }

    func bind<T1, T2, T3, T4, T5>(
        _ action: @escaping (T1, T2, T3, T4, T5) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith5<T1, T2, T3, T4, T5> {
        return { v1, v2, v3, v4, v5 in
            self.dispatch(
                action(v1, v2, v3, v4, v5),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
}
