//===--- ScopeBuilderConditionalTests.swift ------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
@testable import UDF
import Testing

/// Verifies that `@ScopeBuilder` supports `if let` (and `if`/`else`) branches,
/// removing the need for sentinel-value workarounds when scoping to an optional-derived key.
@Suite struct ScopeBuilderConditionalTests {
    struct RootForm: Form {
        var bookToModalPresent: Int? = nil
    }

    struct AppState: AppReducer {
        var rootForm = RootForm()
    }

    struct BookScope: Scope, Equatable {
        let id: Int
    }

    struct EmptyBookScope: Scope, Equatable {}

    @ScopeBuilder
    static func ifLetOnlyScope(for state: AppState) -> Scope {
        if let bookId = state.rootForm.bookToModalPresent {
            BookScope(id: bookId)
        }
    }

    @ScopeBuilder
    static func ifElseScope(for state: AppState) -> Scope {
        if let bookId = state.rootForm.bookToModalPresent {
            BookScope(id: bookId)
        } else {
            EmptyBookScope()
        }
    }

    @Test
    func branchNotTakenIsEqualAcrossStates() {
        let stateA = AppState()
        let stateB = AppState()

        let scopeA = Self.ifLetOnlyScope(for: stateA)
        let scopeB = Self.ifLetOnlyScope(for: stateB)

        #expect(scopeA.isEqual(scopeB))
    }

    @Test
    func branchTakenReflectsTheBoundValue() {
        var stateA = AppState()
        stateA.rootForm.bookToModalPresent = 42

        var stateB = AppState()
        stateB.rootForm.bookToModalPresent = 42

        var stateC = AppState()
        stateC.rootForm.bookToModalPresent = 7

        let scopeA = Self.ifLetOnlyScope(for: stateA)
        let scopeB = Self.ifLetOnlyScope(for: stateB)
        let scopeC = Self.ifLetOnlyScope(for: stateC)

        #expect(scopeA.isEqual(scopeB))
        #expect(!scopeA.isEqual(scopeC))
    }

    @Test
    func switchingBetweenNilAndAValueIsDetectedAsAChange() {
        let stateNil = AppState()
        var stateValue = AppState()
        stateValue.rootForm.bookToModalPresent = 1

        let scopeNil = Self.ifLetOnlyScope(for: stateNil)
        let scopeValue = Self.ifLetOnlyScope(for: stateValue)

        #expect(!scopeNil.isEqual(scopeValue))
        #expect(!scopeValue.isEqual(scopeNil))
    }

    @Test
    func ifElseBranchesAreEquivalentToIfLetOnly() {
        let stateNil = AppState()
        var stateValue = AppState()
        stateValue.rootForm.bookToModalPresent = 42

        #expect(Self.ifElseScope(for: stateNil).isEqual(Self.ifElseScope(for: AppState())))
        #expect(Self.ifElseScope(for: stateValue).isEqual(Self.ifElseScope(for: stateValue)))
        #expect(!Self.ifElseScope(for: stateNil).isEqual(Self.ifElseScope(for: stateValue)))
    }
}
