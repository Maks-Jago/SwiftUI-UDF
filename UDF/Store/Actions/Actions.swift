
import Foundation
import UDFCore

import class CoreLocation.CLLocation
import enum CoreLocation.CLAuthorizationStatus
import enum CoreLocation.CLAccuracyAuthorization

public extension Actions {
    struct UpdateAlertStatus: Action {
        public var status: AlertBuilder.AlertStatus
        public var id: AnyHashable

        public init<Id: Hashable>(status: AlertBuilder.AlertStatus, id: Id) {
            self.status = status
            self.id = id
        }

        public init<Id: Hashable>(style: AlertBuilder.AlertStyle, id: Id) {
            self.status = .init(style: style)
            self.id = id
        }
    }

    struct ResetForm<F: Form>: Action {
        public init() {}
    }

    struct Error: Action, LocalizedError {
        public static func == (lhs: Actions.Error, rhs: Actions.Error) -> Bool {
            lhs.error == rhs.error && lhs.id == rhs.id
        }

        public var error: String?
        public var id: AnyHashable
        public var code: Int
        public var meta: [String: Any]?

        public init<Id: Hashable>(error: String? = nil, id: Id, code: Int? = nil, meta: [String: Any]? = nil) {
            self.error = error?.isEmpty == true ? nil : error
            self.id = AnyHashable(id)
            self.meta = meta
            self.code = if let code {
                code
            } else {
                error?.hashValue ?? -1001
            }
        }

        public var errorDescription: String? { error }
    }

    struct Message: Action {
        public var message: String?
        public var id: AnyHashable

        public init<Id: Hashable>(message: String? = nil, id: Id) {
            self.message = message?.isEmpty == true ? nil : message
            self.id = AnyHashable(id)
        }
    }

    struct LoadPage: Action {
        public var id: AnyHashable
        public var pageNumber: Int

        public init<Id: Hashable>(pageNumber: Int = 1, id: Id) {
            self.pageNumber = pageNumber
            self.id = AnyHashable(id)
        }
    }

    struct SetPaginationItems<I: Equatable>: Action {
        public var id: AnyHashable
        public var items: [I]

        public init<Id: Hashable>(items: [I], id: Id) {
            self.items = items
            self.id = AnyHashable(id)
        }
    }

    struct DidCancelEffect: Action {
        public var cancelation: AnyHashable

        public init<Id: Hashable>(by cancelation: Id) {
            self.cancelation = AnyHashable(cancelation)
        }
    }

    struct ApplicationDidReceiveMemoryWarning: Action {
        public init() {}
    }
}


// MARK: - Location actions
public extension Actions {
    struct RequestLocationAccess: Action {
        public init() {}
    }

    struct DidUpdateLocationAccess: Action {
        public var locationServicesEnabled: Bool
        public var access: CLAuthorizationStatus
        public var accuracyAuthorization: CLAccuracyAuthorization

        public init(locationServicesEnabled: Bool, access: CLAuthorizationStatus, accuracyAuthorization: CLAccuracyAuthorization) {
            self.locationServicesEnabled = locationServicesEnabled
            self.access = access
            self.accuracyAuthorization = accuracyAuthorization
        }
    }

    struct DidUpdateUserLocation: Action {
        public var location: CLLocation

        public init(location: CLLocation) {
            self.location = location
        }
    }
}

// MARK: - Items
public extension Actions {

    struct DidLoadItem<M: Equatable>: Action {
        public var item: M
        public var id: AnyHashable?

        public init(item: M) {
            self.item = item
        }

        public init<Id: Hashable>(item: M, id: Id) {
            self.item = item
            self.id = AnyHashable(id)
        }
    }

    struct DidLoadItems<M: Equatable>: Action, CustomStringConvertible {
        public var items: [M]
        public var id: AnyHashable
        public var shortDescription: Bool

        public init<Id: Hashable>(items: [M], id: Id, shortDescription: Bool = true) {
            self.items = items
            self.id = AnyHashable(id)
            self.shortDescription = shortDescription
        }

        public var description: String {
            guard shortDescription else {
                return "DidLoadItems<\(M.self)>(itemsCount: \(items.count), items:\n\t\t\t\t\t\(items.map { String(describing: $0) }.joined(separator: "\n\t\t\t\t\t")))\n"
            }

            return "DidLoadItems<\(M.self)>(count: \(items.count), prefix(1): \(String(describing: items.prefix(1)))"
        }
    }

    struct DidUpdateItem<M: Equatable>: Action {
        public var item: M
        public var id: AnyHashable?

        public init(item: M) {
            self.item = item
        }

        public init<Id: Hashable>(item: M, id: Id) {
            self.item = item
            self.id = AnyHashable(id)
        }
    }

    struct DeleteItem<M: Equatable>: Action {
        public var item: M
        public var id: AnyHashable?

        public init(item: M) {
            self.item = item
        }

        public init<Id: Hashable>(item: M, id: Id) {
            self.item = item
            self.id = AnyHashable(id)
        }
    }
}

// MARK: - Nested Items
public extension Actions {
    struct DidLoadNestedItem<ParentId: Hashable, Nested: Equatable>: Action {
        public var item: Nested
        public var id: AnyHashable?
        public var parentId: ParentId

        public init(parentId: ParentId, item: Nested) {
            self.item = item
            self.parentId = parentId
        }

        public init<Id: Hashable>(parentId: ParentId, item: Nested, id: Id) {
            self.item = item
            self.id = AnyHashable(id)
            self.parentId = parentId
        }
    }

    struct DidLoadNestedItems<ParentId: Hashable, Nested: Equatable>: Action, CustomStringConvertible {
        public var items: [Nested]
        public var id: AnyHashable?
        public var shortDescription: Bool
        public var parentId: ParentId

        public init(parentId: ParentId, items: [Nested], shortDescription: Bool = true) {
            self.items = items
            self.shortDescription = shortDescription
            self.parentId = parentId
        }

        public init<Id: Hashable>(parentId: ParentId, items: [Nested], id: Id, shortDescription: Bool = true) {
            self.items = items
            self.id = AnyHashable(id)
            self.shortDescription = shortDescription
            self.parentId = parentId
        }

        public var description: String {
            guard shortDescription else {
                return "DidLoadNestedItems<\(Nested.self)> Parent \(String(reflecting: ParentId.self))(itemsCount: \(items.count), items:\n\t\t\t\t\t\(items.map { String(describing: $0) }.joined(separator: "\n\t\t\t\t\t")))\n"
            }

            return "DidLoadNestedItems<\(Nested.self)> Parent \(String(reflecting: ParentId.self))(count: \(items.count), prefix(1): \(String(describing: items.prefix(1)))"
        }
    }

    struct DidLoadNestedByParents<ParentId: Hashable, Nested: Equatable>: Action, CustomStringConvertible {
        public var dictionary: [ParentId: [Nested]]
        public var id: AnyHashable?
        public var shortDescription: Bool

        public init(dictionary: [ParentId: [Nested]], shortDescription: Bool = true) {
            self.shortDescription = shortDescription
            self.dictionary = dictionary
        }

        public init<Id: Hashable>(dictionary: [ParentId: [Nested]], id: Id, shortDescription: Bool = true) {
            self.id = AnyHashable(id)
            self.shortDescription = shortDescription
            self.dictionary = dictionary
        }

        public var description: String {
            guard shortDescription else {
                return "DidLoadNestedByParents<\(Nested.self)> Parent \(String(reflecting: ParentId.self))(parentCount: \(dictionary.keys.count), items:\n\t\t\t\t\t\(dictionary.map { String(describing: $0) }.joined(separator: "\n\t\t\t\t\t")))\n"
            }

            return "DidLoadNestedByParents<\(Nested.self)> Parent \(String(reflecting: ParentId.self))(parentCount: \(dictionary.keys.count), prefix(1): \(String(describing: dictionary.prefix(1)))"
        }
    }

    struct DidUpdateNestedItem<ParentId: Hashable, Nested: Equatable>: Action {
        public var item: Nested
        public var id: AnyHashable?
        public var parentId: ParentId

        public init(parentId: ParentId, item: Nested) {
            self.item = item
            self.parentId = parentId
        }

        public init<Id: Hashable>(parentId: ParentId, item: Nested, id: Id) {
            self.item = item
            self.id = AnyHashable(id)
            self.parentId = parentId
        }
    }

    struct DeleteNestedItem<ParentId: Hashable, Nested: Equatable>: Action {
        public var item: Nested
        public var id: AnyHashable?
        public var parentId: ParentId

        public init(parentId: ParentId, item: Nested) {
            self.item = item
            self.parentId = parentId
        }

        public init<Id: Hashable>(parentId: ParentId, item: Nested, id: Id) {
            self.item = item
            self.id = AnyHashable(id)
            self.parentId = parentId
        }
    }
}
