import Foundation

public extension Collection where Self.Element: Hashable {

    func contains(_ element: AnyHashable) -> Bool {
        contains { elem  in
            AnyHashable(elem) == element
        }
    }
}
