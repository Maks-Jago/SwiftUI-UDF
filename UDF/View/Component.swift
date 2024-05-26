
import SwiftUI

public protocol Component: View {
    associatedtype Props

    var props: Props { get }

    init(props: Props)
}
