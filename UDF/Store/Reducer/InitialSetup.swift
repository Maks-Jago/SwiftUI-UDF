import Foundation

public protocol InitialSetup: Reducing {
    associatedtype AppState: AppReducer

    mutating func initialSetup(with state: AppState)
}

extension AppReducer {
    func callInitialSetup<I: InitialSetup>(_ reducer: I) -> Reducing where I.AppState == Self {
        var mutableCopy = reducer
        mutableCopy.initialSetup(with: self)
        return mutableCopy
    }
}
