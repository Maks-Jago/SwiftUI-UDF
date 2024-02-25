
import Foundation
import Combine

public struct Effect: Effectable, FileFunctionLine {
    public var upstream: AnyPublisher<any Action, Never>

    var fileName: String
    var functionName: String
    var lineNumber: Int

    public init<P: Publisher, A: Action, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        mapper: @escaping (P.Output) -> A) where A: Equatable, P.Failure == Error
    {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber

        self.upstream = Deferred { publisher }
            .map {
                mapper($0)
            }
            .catch {
                Just(Actions.Error(error: $0.localizedDescription, id: id))
            }
            .eraseToAnyPublisher()
    }

    public init<P: Publisher, A: Equatable, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        mapper: @escaping (P.Output) -> A) where P.Failure == Error
    {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber

        self.upstream = Deferred { publisher }
            .map {
                Actions.DidLoadItem(item: mapper($0), id: id)
            }
            .catch {
                Just(Actions.Error(error: $0.localizedDescription, id: id))
            }
            .eraseToAnyPublisher()
    }

    public init<P: Publisher, Item: Equatable, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where P.Failure == Error, P.Output == Array<Item>
    {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber

        self.upstream = Deferred { publisher }
            .map {
                Actions.DidLoadItems(items: $0, id: id)
            }
            .catch {
                Just(Actions.Error(error: $0.localizedDescription, id: id))
            }
            .eraseToAnyPublisher()
    }

    public init<P: Publisher, Item, Id: Hashable, EqItem: Equatable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        mapItem: @escaping (Item) -> EqItem
    ) where P.Failure == Error, P.Output == Array<Item> {

        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber

        self.upstream = Deferred { publisher }
            .map {
                Actions.DidLoadItems<EqItem>(items: $0.map(mapItem), id: id)
            }
            .catch {
                Just(Actions.Error(error: $0.localizedDescription, id: id))
            }
            .eraseToAnyPublisher()
    }


    public init<P: Publisher, Item: Equatable, Id: Hashable>(
        _ publisher: P,
        id: Id,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where P.Failure == Error, P.Output == Item {

        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber

        self.upstream = Deferred { publisher }
            .map {
                Actions.DidLoadItem(item: $0, id: id)
            }
            .catch {
                Just(Actions.Error(error: $0.localizedDescription, id: id))
            }
            .eraseToAnyPublisher()
    }

    public init(
        action: Output,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber

        self.upstream = Deferred {
            Just(action)
        }
        .eraseToAnyPublisher()
    }

    public init(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        _ future: @escaping () -> any Action
    ) {
        self.init(
            action: future(),
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }
}
