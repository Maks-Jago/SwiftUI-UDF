
import Foundation
import Combine

final class UserInputDebouncer<T>: ObservableObject {
    @Published var debouncedValue: T
    @Published var value: T

    private var cancelation: AnyCancellable!

    init(defaultValue: T, debounceTime: TimeInterval = 0.1) {
        value = defaultValue
        debouncedValue = defaultValue

        cancelation = $value
            .debounce(for: .seconds(debounceTime), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                self?.debouncedValue = value
            }
    }
}
