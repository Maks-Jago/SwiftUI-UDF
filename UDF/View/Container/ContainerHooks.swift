
import Foundation
import SwiftUI

final class ContainerHooks<State: AppReducer> {
    weak var store: EnvironmentStore<State>?
    private var subscriptionKey: String = ""

    var hooks: [AnyHashable: Hook<State>] = [:]
    var buildHooks: () -> [Hook<State>]

    init(store: EnvironmentStore<State>, hooks: @escaping () -> [Hook<State>]) {
        self.store = store
        self.buildHooks = hooks
        self.subscriptionKey = store.add { [weak self] _, newState, _ in
            self?.checkHooks(.init(newState))
        }
    }
    
    func createHooks() {
        self.hooks = Dictionary(uniqueKeysWithValues: buildHooks().map { ($0.id, $0) })
    }

    private func checkHooks(_ state: Box<State>) {
        hooks.forEach { (key: AnyHashable, hook: Hook<State>) in
            if hook.condition(state.value), let store {
                hook.block(store)

                switch hook.type {
                case .oneTime:
                    removeHook(by: key)

                case .default:
                    break
                }
            }
        }
    }

    func removeHook(by id: some Hashable) {
        hooks.removeValue(forKey: AnyHashable(id))
    }
    
    func removeAllHooks() {
        hooks.removeAll()
        if let store = store {
            store.removePublisher(forKey: subscriptionKey)
            self.store = nil
        }
    }

    deinit {
        store?.removePublisher(forKey: subscriptionKey)
    }
}
