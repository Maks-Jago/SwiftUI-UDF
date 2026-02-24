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

/// A marker protocol for all dialog components that can be used within a dialog's result builder.
///
/// Concrete components like ``DialogTitle``, ``DialogMessage``, ``DialogIcon``,
/// ``DialogView``, and any ``DialogAction`` conform to this protocol
/// (or one of its sub-protocols) to participate in the DSL-based dialog construction.
public protocol DialogComponent {}

/// A component that is valid inside an ``Alert`` builder.
///
/// Types conforming to this protocol can be used with ``AlertComponentBuilder``.
/// Supported components include ``DialogTitle``, ``DialogMessage``, and any ``DialogAction``.
public protocol AlertComponent: DialogComponent {}

/// A component that is valid inside a ``Toast`` builder.
///
/// Types conforming to this protocol can be used with ``ToastComponentBuilder``.
/// Supported components include ``DialogMessage``, ``DialogIcon``,
/// ``DialogView``, and any ``DialogAction``.
public protocol ToastComponent: DialogComponent {}

/// A component that is valid inside a ``ConfirmationDialog`` builder.
///
/// Types conforming to this protocol can be used with ``ConfirmationDialogComponentBuilder``.
/// Supported components include ``DialogTitle``, ``DialogMessage``, and any ``DialogAction``.
public protocol ConfirmationDialogComponent: DialogComponent {}
