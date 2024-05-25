import Foundation

enum GlobalValue {
    private static var values = [String: AnyObject]()

    static func value<T: AnyObject>(for vType: T.Type) -> T {
        let key = String(describing: T.self)
        if let singleton = values[key] {
            return singleton as! T
        } else {
            fatalError("You have to initialize EnvironmentStore before to use any Containers")
        }
    }

    static func set<T: AnyObject>(_ value: T) {
        let key = String(describing: T.self)
        values[key] = value
    }
}
