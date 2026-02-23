//===--- Alert.swift -----------------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

public protocol DialogComponent {}
public protocol AlertComponent: DialogComponent {}
public protocol ToastComponent: DialogComponent {}
public protocol ConfirmationDialogComponent: DialogComponent {}
