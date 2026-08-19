/// A normalized storage reducer that keeps entities indexed by their identifier.
///
/// `Storage` is the recommended UDF pattern for storing domain models in a single lookup table instead of duplicating models across
/// multiple forms or flows. The storage is usually backed by `Dictionary` or
/// `OrderedDictionary` through the `byId` property.
///
/// ## Example
///
/// ```swift
/// struct AllGenres: Storage {
///     var byId: [Genre.ID: Genre] = [:]
///
///     mutating func reduce(_ action: some Action) {
///         switch action {
///         case let action as Actions.DidLoadItems<Genre>:
///             byId.insert(items: action.items)
///
///         case let action as Actions.DidLoadItem<Genre>:
///             byId.insert(item: action.item)
///
///         case let action as Actions.DidUpdateItem<Genre>:
///             byId[action.item.id] = action.item
///
///         case let action as Actions.DeleteItem<Genre>:
///             byId.removeValue(forKey: action.item.id)
///
///         default:
///             break
///         }
///     }
/// }
/// ```
///
/// In this example, `AllGenres` becomes the single source of truth for every loaded
/// `Genre`. Other reducers can then reference `Genre.ID` values instead of storing
/// duplicated full models.
public protocol Storage<Entity>: Reducible {
    associatedtype Entity: StorageItem
    associatedtype Entities: StorageCollection where Entities.Key == Entity.ID, Entities.Value == Entity

    /// The normalized lookup table keyed by entity identifier.
    var byId: Entities { get set }
    
    /// Returns the entity for the provided identifier.
    ///
    /// Types conforming to `EmptyValue` can provide a non-optional implementation
    /// through the default extension below.
    func by(id: Entity.ID) -> Entity
}

public extension Storage {
    /// Convenience access to the underlying storage collection.
    subscript(id: Entity.ID) -> Entity? {
        return byId[id]
    }
}

public extension Storage {
    /// Returns `.empty` when the entity is missing from storage.
    func by(id: Entity.ID) -> Entity {
        self[id] ?? .empty
    }
}
