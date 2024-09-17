
import Foundation

public struct Hook<State: AppReducer> {
    let id: AnyHashable
    let type: HookType
    let condition: (_ state: State) -> Bool
    let block: (_ store: EnvironmentStore<State>) -> Void
    
    public init(
        id: AnyHashable,
        type: HookType = .default,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) {
        self.id = id
        self.type = type
        self.condition = condition
        self.block = block
    }
    
    public static func hook(
        id: AnyHashable,
        type: HookType = .default,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) -> Hook {
        Hook(
            id: id,
            type: type,
            condition: { state in
                condition(state)
            },
            block: { store in
                block(store)
            }
        )
    }
    
    public static func oneTimeHook(
        id: AnyHashable,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) -> Hook {
        hook(id: id, type: .oneTime, condition: condition, block: block)
    }
}
