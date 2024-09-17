import Foundation

class HooksHolder<ContainerState: AppReducer>: ObservableObject {
    let hooks: [Hook<ContainerState>]
    
    init(hooks: [Hook<ContainerState>]) {
        self.hooks = hooks
    }
}
