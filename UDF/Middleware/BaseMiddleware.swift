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
    public typealias ErrorMapper<Id> = (_ id: Id, _ error: Error) -> any Action

    public var cancelations: [AnyHashable: CancellableTask] = [:]
    
    // MARK: - Cancellation
    @discardableResult
    open func cancel<Id: Hashable>(by cancelation: Id) -> Bool {
        let anyId = AnyHashable(cancelation)

        guard let cancellableTask = cancelations[anyId] else {
            return false
        }

        cancellableTask.cancel()
        cancelations[anyId] = nil
        return true
    }

    open func cancelAll() {
        cancelations.keys.forEach { cancel(by: $0) }
    }

    // MARK: - Combine
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
            })
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
            mapAction: mapAction,
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
    
    // MARK: - Concurrency
    open func execute<TaskId: Hashable>(
        id: TaskId,
        cancelation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<TaskId> = { effectId, error in Actions.Error(error: error.localizedDescription, id: effectId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        _ task: @escaping (TaskId) async throws -> any Action
    ) {
        execute(
            ConcurrencyBlockEffect(
                id: id,
                block: task,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            ),
            cancelation: cancelation,
            mapAction: mapAction,
            mapError: mapError
        )
    }

    private func dispatch(action: any Action, filePosition: FileFunctionLineDescription) {
        queue.sync { [weak self] in
            self?.store.dispatch(
                action,
                fileName: filePosition.fileName,
                functionName: filePosition.functionName,
                lineNumber: filePosition.lineNumber
            )
            XCTestGroup.leave()
        }
    }
    
    open func execute<Id: Hashable, E: ConcurrencyEffect>(
        _ effect: E,
        cancelation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<E.Id> = { effectId, error in Actions.Error(error: error.localizedDescription, id: effectId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        let anyId = AnyHashable(cancelation)

        guard cancelations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        XCTestGroup.enter()
        let task = Task { [weak self] in
            do {
                let action = try await effect.task()
                if Task.isCancelled {
                    self?.dispatch(action: Actions.DidCancelEffect(by: cancelation), filePosition: filePosition)

                } else {
                    self?.dispatch(action: mapAction(action), filePosition: filePosition)
                }

            } catch let error {
                if error is CancellationError {
                    self?.dispatch(action: Actions.DidCancelEffect(by: cancelation), filePosition: filePosition)

                } else if !Task.isCancelled {
                    self?.dispatch(action: mapError(effect.id, error), filePosition: filePosition)
                }
            }

            _ = self?.queue.sync { [weak self] in
                self?.cancelations.removeValue(forKey: anyId)
            }
        }

        cancelations[anyId] = task
    }
}
