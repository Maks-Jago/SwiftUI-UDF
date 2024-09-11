
import Foundation

protocol _AnyBindableAction: Action {
    associatedtype BindedContainer: BindableContainer

    var value: any Action { get }
    var containerType: BindedContainer.Type { get }
    var id: BindedContainer.ID { get }
}
