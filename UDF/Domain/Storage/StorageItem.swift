/// A protocol for models that can be stored in a UDF storage reducer.
///
/// Conforming types provide an `empty` value that represents missing
/// or unavailable storage data.
public protocol StorageItem: Identifiable, Sendable, Equatable {
    /// A placeholder instance representing the absence of loaded storage data.
    static var empty: Self { get }
}
