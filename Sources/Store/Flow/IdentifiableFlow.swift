//
//  IdentifiableFlow.swift
//  
//
//  Created by Max Kuznetsov on 21.10.2020.
//

import Foundation

public protocol IdentifiableFlow: Flow {
    associatedtype FlowId
    
    static var id: FlowId { get }
}

public extension IdentifiableFlow where FlowId == Flows.Id {
    static var id: FlowId { FlowId(value: String(describing: Self.self)) }
}
