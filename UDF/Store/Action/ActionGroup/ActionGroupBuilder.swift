//
//  ActionGroupBuilder.swift
//  
//
//  Created by Max Kuznetsov on 22.02.2021.
//

import Foundation

@resultBuilder
public enum ActionGroupBuilder {

    private static func toInternalActions(
        _ actions: [any Equatable],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [InternalAction] {

        actions.compactMap {
            switch ($0) {
            case let action as InternalAction:
                return action
            case let action as any Action:
                return InternalAction(
                    action,
                    fileName: fileName,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
            default:
                return nil
            }
        }
    }

    public static func buildArray(
        _ components: [[any Equatable]],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [any Equatable] {

        let actions = components.flatMap { $0 }
        return toInternalActions(
            actions,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    public static func buildBlock(
        _ components: [any Equatable]...,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [any Equatable] {
        let actions = components.flatMap { $0 }
        return toInternalActions(
            actions,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    public static func buildExpression(
        _ expression: some Action,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [any Equatable] {
        [
            InternalAction(
                expression,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        ]
    }

    public static func buildExpression(_ expression: Void) -> [any Equatable] {
        []
    }

    public static func buildOptional(_ component: [any Equatable]?) -> [any Equatable] {
        component ?? []
    }

    public static func buildEither(first component: [any Equatable]) -> [any Equatable] {
        component
    }

    public static func buildEither(second component: [any Equatable]) -> [any Equatable] {
        component
    }

    public static func buildLimitedAvailability(_ component: [any Equatable]) -> [any Equatable] {
        component
    }

    public static func buildFinalResult(
        _ component: [any Equatable],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> ActionGroup {

        ActionGroup(
            internalActions: toInternalActions(
                component,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        )
    }
}
