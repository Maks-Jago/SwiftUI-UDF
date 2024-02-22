
import UDFCore
import Foundation
import Combine

open class BaseMiddleware<State: AppReducer>: Middleware {
    public var store: any Store<State>
    public var queue: DispatchQueue

    required public init(store: some Store<State>, queue: DispatchQueue) {
        self.store = store
        self.queue = queue
    }

    open func status(for state: State) -> MiddlewareStatus { .active }

    public typealias DispatchFilter<Output> = (_ state: State, _ output: Output) -> Bool

    public var cancelations: [AnyHashable: AnyCancellable] = [:]

    open func execute<E, Id>(
        _ effect: E,
        cancelation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancelation)

        guard cancelations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        XCTestGroup.enter()
        cancelations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                self?.cancelations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancelation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
                XCTestGroup.leave()
            })
            .sink(receiveCompletion: { [weak self] _ in
                self?.cancelations[anyId] = nil
                XCTestGroup.leave()
            }, receiveValue: { [weak self] action in
                if self?.cancelations[anyId] != nil {
                    self?.store.dispatch(
                        mapAction(action),
                        fileName: filePosition.fileName,
                        functionName: filePosition.functionName,
                        lineNumber: filePosition.lineNumber
                    )
                }
                XCTestGroup.leave()
            })
        XCTestGroup.wait()
    }

    open func execute<E, Id>(
        _ effect: E,
        cancelation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect & ErasableToEffect, Id: Hashable {
        execute(
            effect.asEffectable,
            cancelation: cancelation,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    open func run<E, Id>(
        _ effect: E,
        cancelation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: @escaping DispatchFilter<any Action>,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancelation)

        guard cancelations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        cancelations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                self?.cancelations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancelation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
            })
            .flatMap { [unowned self] action in
                Publishers.IsolatedState(from: self.store)
                    .map { state in
                        (state: state, action: action)
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [weak self] _ in
                self?.cancelations[anyId] = nil
            }, receiveValue: { [weak self] result in
                if self?.cancelations[anyId] != nil, dispatchFilter(result.state, result.action) {
                    self?.store.dispatch(
                        mapAction(result.action),
                        fileName: filePosition.fileName,
                        functionName: filePosition.functionName,
                        lineNumber: filePosition.lineNumber
                    )
                }
            })
    }

    open func run<E, Id>(
        _ effect: E,
        cancelation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancelation)

        guard cancelations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        cancelations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                self?.cancelations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancelation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
            })
            .sink(receiveCompletion: { [weak self] _ in
                self?.cancelations[anyId] = nil
            }, receiveValue: { [weak self] action in
                if self?.cancelations[anyId] != nil {
                    self?.store.dispatch(
                        mapAction(action),
                        fileName: filePosition.fileName,
                        functionName: filePosition.functionName,
                        lineNumber: filePosition.lineNumber
                    )
                }
            })
    }

    @discardableResult
    open func cancel<Id: Hashable>(by cancelation: Id) -> Bool {
        let anyId = AnyHashable(cancelation)

        guard let cancellable = cancelations[anyId] else {
            return false
        }

        cancellable.cancel()
        cancelations[anyId] = nil
        return true
    }

    open func cancelAll() {
        cancelations.keys.forEach { cancel(by: $0) }
    }
}
