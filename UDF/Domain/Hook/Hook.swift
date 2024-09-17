
import Foundation

public struct Hook<State: AppReducer> {
    let id: AnyHashable
    let type: HookType
    let condition: (_ state: State) -> Bool
    let block: (_ store: EnvironmentStore<State>) -> Void
}
