//
//  AnyHashable+Sendable.swift
//  SwiftUI-UDF
//
//  Created by Arthur Zavolovych on 05.06.2025.
//

import Foundation

extension AnyHashable: @unchecked @retroactive Sendable {}
