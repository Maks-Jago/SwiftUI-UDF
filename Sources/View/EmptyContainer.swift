//
//  EmptyContainer.swift
//  
//
//  Created by Max Kuznetsov on 20.09.2021.
//

import SwiftUI

public func empty() -> RenderContainer<EmptyView> {
    RenderContainer(viewToRender: EmptyView())
}

public func empty<T>(_ value: T) -> RenderContainer<EmptyView> {
    RenderContainer(viewToRender: EmptyView())
}
