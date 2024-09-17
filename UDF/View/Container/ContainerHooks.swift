
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
        self.subscriptionKey = store.add { [weak self] oldState, newState, _ in
            self?.checkHooks(oldState: .init(oldState), newState: .init(newState))
        }
    }
    
    func createHooks() {
        self.hooks = Dictionary(uniqueKeysWithValues: buildHooks().map { ($0.id, $0) })
    }

    private func checkHooks(oldState: Box<State>, newState: Box<State>) {
        hooks.forEach { (key: AnyHashable, hook: Hook<State>) in
            if hook.condition(newState.value), !hook.condition(oldState.value), let store {
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
        
        if hooks.isEmpty {
            store?.removePublisher(forKey: subscriptionKey)
        }
    }
    
    func removeAllHooks() {
        hooks.removeAll()
        store?.removePublisher(forKey: subscriptionKey)
    }

    deinit {
        store?.removePublisher(forKey: subscriptionKey)
    }
}
