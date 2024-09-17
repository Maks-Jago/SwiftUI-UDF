import Foundation

public class HookBuilder<State: AppReducer> {
    private var hooks: [Hook<State>] = []
    
    @discardableResult
    func addHook(
        id: AnyHashable,
        type: HookType = .default,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) -> HookBuilder<State> {
        let hook = Hook<State>(id: id, type: type, condition: condition, block: block)
        hooks.append(hook)
        return self
    }
    
    func build() -> [Hook<State>] {
        return hooks
    }
}

extension HookBuilder {
    @discardableResult
    func addHook(
        id: AnyHashable,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) -> HookBuilder<State> {
        addHook(id: id, type: .default, condition: condition, block: block)
    }
    
    @discardableResult
    func addOneTimeHook(
        id: AnyHashable,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) -> HookBuilder<State> {
        addHook(id: id, type: .oneTime, condition: condition, block: block)
    }
}
