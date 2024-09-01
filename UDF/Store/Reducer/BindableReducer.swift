
import Foundation

@propertyWrapper
public struct BindableReducer<BindedContainer: BindableContainer, Reducer: Reducing & Equatable>: Reducible {
    public typealias Reducers = [BindedContainer.ID: Reducer]

    var containerType: BindedContainer.Type

    var reducers: Reducers = [:]
    public var wrappedValue: BindableReducer<BindedContainer, Reducer> { self }

    public init(_ reducerType: Reducer.Type, containerType: BindedContainer.Type) {
        self.containerType = containerType
    }

    public init() {
        fatalError("use init(containerType:reducerType:) instead init")
    }

    public static func == (lhs: BindableReducer<BindedContainer, Reducer>, rhs: BindableReducer<BindedContainer, Reducer>) -> Bool {
        lhs.reducers == rhs.reducers
    }

    public subscript(_ id: BindedContainer.ID) -> Reducer {
        reducers[id]!
    }

    public subscript(_ id: BindedContainer.ID) -> Reducer? {
        reducers[id]
    }
}

// MARK: Runtime reducing
extension BindableReducer {
    mutating public func reduce(_ action: some Action) {
        for var tuple in reducers {
            _ = RuntimeReducing.reduce(action, reducer: &tuple.value)
            reducers.updateValue(tuple.value, forKey: tuple.key)
        }

        switch action {
        case let action as Actions._OnContainerDidLoad<BindedContainer>:
            reducers[action.id] = .init()

        case let action as Actions._OnContainerDidUnLoad<BindedContainer>:
            reducers.removeValue(forKey: action.id)

        default:
            break
        }
    }
}
