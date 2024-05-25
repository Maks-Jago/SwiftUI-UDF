import Foundation
import SwiftUI

typealias StateSubscriber<State: AppReducer> = (_ oldState: State, _ newState: State, _ animation: Animation?) -> Void

actor SubscribersCoordinator<T> {
    private var subscribers: [String: T] = [:]

    @discardableResult
    func add(subscriber: T, for key: String = UUID().uuidString) -> String {
        subscribers[key] = subscriber
        return key
    }

    func removeSubscriber(forKey key: String) {
        subscribers.removeValue(forKey: key)
    }

    func allSubscibers() -> Dictionary<String, T>.Values {
        subscribers.values
    }
}
