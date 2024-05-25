//
//  ProcessInfo.swift
//  
//
//  Created by Max Kuznetsov on 04.11.2022.
//

import Foundation

public extension ProcessInfo {
    var xcTest: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
