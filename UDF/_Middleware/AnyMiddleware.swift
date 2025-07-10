//===--- AnyMiddleware.swift ------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

final class AnyMiddleware: Hashable, Sendable {
    let middleware: any _Middleware

    init(_ middleware: any _Middleware) {
        self.middleware = middleware
    }

    static func == (lhs: AnyMiddleware, rhs: AnyMiddleware) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
