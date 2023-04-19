
import UDFCore
import SwiftUI

public protocol Container: _Container {}

public extension Container {
    @MainActor func onContainerAppear(store: EnvironmentStore<ContainerState>) {}
    @MainActor func onContainerDisappear(store: EnvironmentStore<ContainerState>) {}
    @MainActor func onContainerDidLoad(store: EnvironmentStore<ContainerState>) {}
}
