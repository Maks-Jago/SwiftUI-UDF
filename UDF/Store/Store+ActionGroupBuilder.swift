//
//  Store+ActionGroupBuilder.swift
//  SwiftUI-UDF
//
//  Created by Oleksandr Bodnar on 20.05.2026.
//

import Foundation

public extension Store {
    nonisolated func dispatch(
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        @ActionGroupBuilder _ builder: () -> ActionGroup
    ) {
        dispatch(
            builder(),
            priority: priority,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }
}
