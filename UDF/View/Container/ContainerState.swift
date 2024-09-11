import Foundation
import SwiftUI

final class ContainerState<State: AppReducer>: ObservableObject {
    weak var store: EnvironmentStore<State>?
    private var subscriptionKey: String = ""

    @Published var currentScope: Scope?

    init(store: EnvironmentStore<State>, scope: @escaping (_ state: State) -> Scope) {
        self.store = store
        self.currentScope = nil

        self.subscriptionKey = store.add { [weak self] oldState, newState, animation in
            let oldScope = scope(oldState)
            let newScope = scope(newState)

            if !oldScope.isEqual(newScope) {
                withAnimation(animation) {
                    self?.currentScope = newScope
                }
            }
        }
    }

    deinit {
        store?.removePublisher(forKey: subscriptionKey)
    }
}
