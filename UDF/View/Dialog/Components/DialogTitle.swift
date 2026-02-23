//===--- DialogComponents.swift ----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

public struct DialogTitle: AlertComponent, ConfirmationDialogComponent {
    let value: String
    
    public init(_ value: String) {
        self.value = value
    }
}
