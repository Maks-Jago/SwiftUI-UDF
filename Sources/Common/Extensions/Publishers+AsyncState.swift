import Foundation
import Combine

public extension Publishers {
    static func IsolatedState<State: AppReducer>(from store: any Store<State>) -> AnyPublisher<State, Never> {
        Future { promise in
            Task.detached(priority: .high) {
                let immutableState = await store.state
                promise(.success(immutableState))
            }
        }
        .eraseToAnyPublisher()
    }
}
