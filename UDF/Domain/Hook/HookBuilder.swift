import Foundation

@resultBuilder
public struct HookBuilder<State: AppReducer> {
    public static func buildBlock(_ components: Hook<State>...) -> [Hook<State>] {
        components
    }
    
    public static func buildExpression(_ expression: Hook<State>) -> Hook<State> {
        expression
    }
    
    public static func buildOptional(_ component: Hook<State>?) -> [Hook<State>] {
        component.map { [$0] } ?? []
    }
    
    public static func buildEither(first component: [Hook<State>]) -> [Hook<State>] {
        component
    }
    
    public static func buildEither(second component: [Hook<State>]) -> [Hook<State>] {
        component
    }
    
    public static func buildArray(_ components: [[Hook<State>]]) -> [Hook<State>] {
        components.flatMap { $0 }
    }
    
    public static func buildPartialBlock(first: Hook<State>) -> [Hook<State>] {
        [first]
    }
    
    public static func buildPartialBlock(accumulated: [Hook<State>], next: Hook<State>) -> [Hook<State>] {
        accumulated + [next]
    }
    
    public static func buildFinalResult(_ component: [Hook<State>]) -> [Hook<State>] {
        component
    }
}
