/// A collection-like storage abstraction used by `Storage`.
///
/// `StorageCollection` allows UDF storage reducers to be backed by different key-value
/// containers while exposing a consistent API for entity lookup.
///
/// Common conforming types in this package are:
/// - `Dictionary`
/// - `OrderedDictionary`
///
/// Use `Dictionary` when ordering is irrelevant. Use `OrderedDictionary` when you need
/// stable insertion order in addition to keyed access.
public protocol StorageCollection: Sequence, Sendable {
    associatedtype Key: Hashable
    associatedtype Value

    subscript(key: Key) -> Value? { get set }
    
    var count: Int { get }
    var isEmpty: Bool { get }
}

extension OrderedDictionary: StorageCollection { }
extension Dictionary: StorageCollection { }
