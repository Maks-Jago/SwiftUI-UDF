
import Foundation

struct Hook<State: AppReducer> {
    let type: HookType
    let condition: (_ state: State) -> Bool
    let block: (_ store: EnvironmentStore<State>) -> Void
}
