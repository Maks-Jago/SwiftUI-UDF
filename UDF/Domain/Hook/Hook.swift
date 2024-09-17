
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
}
