
import UDFCore
import Foundation

open class BaseConcurrencyMiddleware<State: AppReducer>: Middleware {
    public var store: any Store<State>
    public var queue: DispatchQueue

    public var cancelations: [AnyHashable: Task<Void, Never>] = [:]

    public required convenience init(store: some Store<State>) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, queue: DispatchQueue(label: queueLabel))
    }

    required public init(store: some Store<State>, queue: DispatchQueue) {
        self.store = store
        self.queue = queue
    }

    open func status(for state: State) -> MiddlewareStatus { .active }

    open func execute<TaskId: Hashable>(
        id: TaskId,
        cancelation: some Hashable,
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
            cancelation: cancelation
        )
    }

    private func dispatch(action: any Action, filePosition: FileFunctionLineDescription) {
        queue.async { [weak self] in
            self?.store.dispatch(
                action,
                fileName: filePosition.fileName,
                functionName: filePosition.functionName,
                lineNumber: filePosition.lineNumber
            )
        }
    }

    open func execute<Id: Hashable>(
        _ effect: some ConcurrencyEffect,
        cancelation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        let anyId = AnyHashable(cancelation)

        guard cancelations[anyId] == nil else {
            return
        }

        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

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
                    self?.dispatch(action: Actions.Error(error: error.localizedDescription, id: effect.id), filePosition: filePosition)
                }
            }

            _ = self?.queue.sync { [weak self] in
                self?.cancelations.removeValue(forKey: anyId)
            }
        }

        cancelations[anyId] = task
    }

    @discardableResult
    open func cancel<Id: Hashable>(by cancelation: Id) -> Bool {
        let anyId = AnyHashable(cancelation)

        guard let task = cancelations[anyId] else {
            return false
        }

        task.cancel()
        cancelations[anyId] = nil
        return true
    }

    open func cancelAll() {
        cancelations.keys.forEach { cancel(by: $0) }
    }
}

public typealias BaseConcurrencyObservableMiddleware<State: AppReducer> = BaseConcurrencyMiddleware<State> & ObservableMiddleware & EnvironmentMiddleware
public typealias BaseConcurrencyReducibleMiddleware<State: AppReducer> = BaseConcurrencyMiddleware<State> & ReducibleMiddleware & EnvironmentMiddleware

