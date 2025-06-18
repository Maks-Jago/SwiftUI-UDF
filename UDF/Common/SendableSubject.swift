//===--- SendableSubject.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Combine

final class SendableSubject<Output, Failure: Error>: @unchecked Sendable {
    private let _subject: PassthroughSubject<Output, Failure>
    private let lock = NSLock()
    
    init() {
        self._subject = PassthroughSubject<Output, Failure>()
    }
    
    func send(_ value: Output) {
        lock.lock()
        defer { lock.unlock() }
        _subject.send(value)
    }
    
    func send(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        defer { lock.unlock() }
        _subject.send(completion: completion)
    }
    
    var publisher: AnyPublisher<Output, Failure> {
        lock.lock()
        defer { lock.unlock() }
        return _subject.eraseToAnyPublisher()
    }
    
    func subscribe<S: Subscriber>(_ subscriber: S) where S.Input == Output, S.Failure == Failure {
        lock.lock()
        defer { lock.unlock() }
        _subject.subscribe(subscriber)
    }
    
    func sink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void = { _ in },
        receiveValue: @escaping (Output) -> Void
    ) -> AnyCancellable {
        lock.lock()
        defer { lock.unlock() }
        return _subject.sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
    }
    
    func map<T>(_ transform: @escaping (Output) -> T) -> Publishers.Map<PassthroughSubject<Output, Failure>, T> {
        lock.lock()
        defer { lock.unlock() }
        return _subject.map(transform)
    }
}
