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

    public var cancellations: [AnyHashable: CancellableTask] = [:]
    
    // MARK: - Cancellation
    @discardableResult
    open func cancel<Id: Hashable>(by cancellation: Id) -> Bool {
        let anyId = AnyHashable(cancellation)

        guard let cancellableTask = cancellations[anyId] else {
            return false
        }

        cancellableTask.cancel()
        cancellations[anyId] = nil
        return true
    }

    open func cancelAll() {
        cancellations.keys.forEach { cancel(by: $0) }
    }

    // MARK: - Combine
    open func execute<E, Id>(
        _ effect: E,
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancellation)

        guard cancellations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        XCTestGroup.enter()
        cancellations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                self?.cancellations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancellation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
                XCTestGroup.leave()
            })
            .sink(receiveCompletion: { [weak self] _ in
                self?.cancellations[anyId] = nil
                XCTestGroup.leave()
            }, receiveValue: { [weak self] action in
                if self?.cancellations[anyId] != nil {
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
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect & ErasableToEffect, Id: Hashable {
        execute(
            effect.asEffectable,
            cancellation: cancellation,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    open func run<E, Id>(
        _ effect: E,
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: @escaping DispatchFilter<any Action>,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancellation)

        guard cancellations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        cancellations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                self?.cancellations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancellation),
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
                self?.cancellations[anyId] = nil
            }, receiveValue: { [weak self] result in
                if self?.cancellations[anyId] != nil, dispatchFilter(result.state, result.action) {
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
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancellation)

        guard cancellations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        cancellations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                self?.cancellations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancellation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
            })
            .sink(receiveCompletion: { [weak self] _ in
                self?.cancellations[anyId] = nil
            }, receiveValue: { [weak self] action in
                if self?.cancellations[anyId] != nil {
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
        cancellation: some Hashable,
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
            cancellation: cancellation,
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
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<E.Id> = { effectId, error in Actions.Error(error: error.localizedDescription, id: effectId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        let anyId = AnyHashable(cancellation)

        guard cancellations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        XCTestGroup.enter()
        let task = Task { [weak self] in
            do {
                let action = try await effect.task()
                if Task.isCancelled {
                    self?.dispatch(action: Actions.DidCancelEffect(by: cancellation), filePosition: filePosition)

                } else {
                    self?.dispatch(action: mapAction(action), filePosition: filePosition)
                }

            } catch let error {
                if error is CancellationError {
                    self?.dispatch(action: Actions.DidCancelEffect(by: cancellation), filePosition: filePosition)

                } else if !Task.isCancelled {
                    self?.dispatch(action: mapError(effect.id, error), filePosition: filePosition)
                }
            }

            _ = self?.queue.sync { [weak self] in
                self?.cancellations.removeValue(forKey: anyId)
            }
        }

        cancellations[anyId] = task
    }
}
