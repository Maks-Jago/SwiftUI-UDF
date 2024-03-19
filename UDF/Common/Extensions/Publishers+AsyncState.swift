import Foundation
import Combine

public extension Publishers {
    static func IsolatedState<State: AppReducer>(from store: any Store) -> AnyPublisher<State, Never> {
        Future { promise in
            Task.detached(priority: .high) {
                let immutableState = await store.state
                promise(.success(immutableState as! State))
            }
        }
        .eraseToAnyPublisher()
    }
}
