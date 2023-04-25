
import Foundation

public protocol ConcurrencyEffect {
    associatedtype Id: Hashable

    var id: Id { get }

    func task() async throws -> any Action
}

struct ConcurrencyBlockEffect<EffectId: Hashable>: ConcurrencyEffect, FileFunctionLine {
    typealias Id = EffectId

    var id: EffectId
    let block: (EffectId) async throws -> any Action

    var fileName: String
    var functionName: String
    var lineNumber: Int

    func task() async throws -> any Action {
        try await block(id)
    }
}
