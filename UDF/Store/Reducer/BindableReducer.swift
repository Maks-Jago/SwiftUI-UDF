
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

    public subscript(_ id: BindedContainer.ID) -> Reducer? {
        get { reducers[id] }
        set { reducers[id] = newValue }
    }

//    public subscript(_ id: BindedContainer.ID) -> ReducerReference<BindedContainer.ContainerState, Reducer> {
//        .init(reducer: reducers[id]!, store: store)
//    }

    public subscript(_ id: BindedContainer.ID) -> ReducerScope<Reducer> {
        ReducerScope(reducer: reducers[id])
    }
}

// MARK: - Collection
extension BindableReducer: Collection {
    public typealias Index = Reducers.Index
    public typealias Element = Reducers.Element

    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Index { reducers.startIndex }
    public var endIndex: Index { reducers.endIndex }

    // Required subscript, based on a dictionary index
    public subscript(index: Index) -> Reducers.Element {
        get { reducers[index] }
    }

    // Method that returns the next index when iterating
    public func index(after i: Index) -> Index {
        reducers.index(after: i)
    }
}

// MARK: - Runtime reducing
extension BindableReducer {
    mutating public func reduce(_ action: some Action) {
        //TODO: Thinking, should a Bindable Reducer reduce non-bindable actions?
//        for var tuple in reducers {
//            _ = RuntimeReducing.reduce(action, reducer: &tuple.value)
//            reducers.updateValue(tuple.value, forKey: tuple.key)
//        }

        switch action {
        case let action as Actions._OnContainerDidLoad<BindedContainer>:
            reducers[action.id] = .init()

        case let action as Actions._OnContainerDidUnLoad<BindedContainer>:
            reducers.removeValue(forKey: action.id)

        case let action as Actions.BindableAction<BindedContainer>:
            if var reducer = reducers[action.id] {
                _ = RuntimeReducing.bindableReduce(action.value, reducer: &reducer)
                reducers.updateValue(reducer, forKey: action.id)
            }

        default:
            break
        }
    }
}
