
import Foundation
import SwiftUI

final class ContainerHooks<State: AppReducer> {
    weak var store: EnvironmentStore<State>?
    private var subscriptionKey: String = ""

    var hooks: [AnyHashable: Hook<State>] = [:]

    init(store: EnvironmentStore<State>, hooks: [Hook<State>]) {
        self.store = store
        self.hooks = Dictionary(uniqueKeysWithValues: hooks.map { ($0.id, $0) })
        self.subscriptionKey = store.add { [weak self] _, newState, _ in
            self?.checkHooks(.init(newState))
        }
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
