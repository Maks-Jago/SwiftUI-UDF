
import Foundation
import SwiftUI

final class ContainerLifecycle<State: AppReducer>: ObservableObject {
    private var didLoad: Bool = false

    let containerHooks: ContainerHooks<State>

    func set(didLoad: Bool, store: EnvironmentStore<State>) {
        if !self.didLoad, didLoad {
            didLoadCommand(store)
        }

        self.didLoad = didLoad
    }

    var didLoadCommand: CommandWith<EnvironmentStore<State>>
    var didUnloadCommand: CommandWith<EnvironmentStore<State>>

    init(
        didLoadCommand: @escaping CommandWith<EnvironmentStore<State>>,
        didUnloadCommand: @escaping CommandWith<EnvironmentStore<State>>,
        hooks: [Hook<State>]
    ) {
        self.didLoadCommand = didLoadCommand
        self.didUnloadCommand = didUnloadCommand
        self.containerHooks = .init(store: EnvironmentStore<State>.global, hooks: hooks)
    }

    deinit {
        containerHooks.removeAllHooks()
        self.didUnloadCommand(EnvironmentStore<State>.global)
    }
}
