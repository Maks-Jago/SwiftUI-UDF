//
//  ContainerLifecycle.swift
//
//
//  Created by Max Kuznetsov on 07.09.2024.
//

import Foundation
import SwiftUI

final class ContainerLifecycle<State: AppReducer>: ObservableObject {
    private var didLoad: Bool = false

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
        didUnloadCommand: @escaping CommandWith<EnvironmentStore<State>>
    ) {
        self.didLoadCommand = didLoadCommand
        self.didUnloadCommand = didUnloadCommand
    }

    deinit {
        self.didUnloadCommand(EnvironmentStore<State>.global)
    }
}
