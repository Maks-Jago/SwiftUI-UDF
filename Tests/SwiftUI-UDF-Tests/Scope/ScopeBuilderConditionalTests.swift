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

    struct TailForm: Form {
        var counter: Int = 0
    }

    struct AppState: AppReducer {
        var rootForm = RootForm()
        var tailForm = TailForm()
    }

    struct MockBook: Scope, Equatable {
        let id: Int
    }

    struct MockAlternateBook: Scope, Equatable {
        let id: Int
    }

    struct MockEmptyBook: Scope, Equatable {}

    @ScopeBuilder
    static func ifLetOnlyScope(for state: AppState) -> Scope {
        if let bookId = state.rootForm.bookToModalPresent {
            MockBook(id: bookId)
        }
    }

    @ScopeBuilder
    static func ifElseScope(for state: AppState) -> Scope {
        if let bookId = state.rootForm.bookToModalPresent {
            MockBook(id: bookId)
        } else {
            MockEmptyBook()
        }
    }

    /// Mirrors the real shape used in `RootContainer.scope(for:)`: an `if let` branch
    /// followed by unconditional statements in the same builder block.
    @ScopeBuilder
    static func combinedScope(for state: AppState) -> Scope {
        if let bookId = state.rootForm.bookToModalPresent {
            MockBook(id: bookId)
        }
        state.tailForm
    }

    /// A condition nested inside another condition, to make sure `EitherScope`/`OptionalScope`
    /// compose correctly when layered.
    @ScopeBuilder
    static func nestedConditionScope(for state: AppState) -> Scope {
        if let bookId = state.rootForm.bookToModalPresent {
            if bookId > 100 {
                MockAlternateBook(id: bookId)
            } else {
                MockBook(id: bookId)
            }
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

    // MARK: - Combined scope (if let + unconditional trailing statements, like `RootContainer`)

    @Test
    func combinedScopeIsEqualWhenNothingChanged() {
        let stateA = AppState()
        let stateB = AppState()

        #expect(Self.combinedScope(for: stateA).isEqual(Self.combinedScope(for: stateB)))
    }

    @Test
    func combinedScopeDetectsChangeInTheConditionalPartOnly() {
        let stateNil = AppState()
        var stateValue = AppState()
        stateValue.rootForm.bookToModalPresent = 1
        // tailForm stays identical in both states

        #expect(!Self.combinedScope(for: stateNil).isEqual(Self.combinedScope(for: stateValue)))
    }

    @Test
    func combinedScopeDetectsChangeInTheTrailingUnconditionalPartOnly() {
        var stateA = AppState()
        stateA.rootForm.bookToModalPresent = 1

        var stateB = AppState()
        stateB.rootForm.bookToModalPresent = 1
        stateB.tailForm.counter = 1
        // the conditional part (bookToModalPresent) is identical in both states

        #expect(!Self.combinedScope(for: stateA).isEqual(Self.combinedScope(for: stateB)))
    }

    @Test
    func combinedScopeIsEqualWhenBothPartsMatch() {
        var stateA = AppState()
        stateA.rootForm.bookToModalPresent = 1
        stateA.tailForm.counter = 5

        var stateB = AppState()
        stateB.rootForm.bookToModalPresent = 1
        stateB.tailForm.counter = 5

        #expect(Self.combinedScope(for: stateA).isEqual(Self.combinedScope(for: stateB)))
    }

    // MARK: - Nested conditions

    @Test
    func nestedConditionBranchNotTakenIsEqualAcrossStates() {
        let stateA = AppState()
        let stateB = AppState()

        #expect(Self.nestedConditionScope(for: stateA).isEqual(Self.nestedConditionScope(for: stateB)))
    }

    @Test
    func nestedConditionSameInnerBranchWithSameValueIsEqual() {
        var stateA = AppState()
        stateA.rootForm.bookToModalPresent = 5

        var stateB = AppState()
        stateB.rootForm.bookToModalPresent = 5

        #expect(Self.nestedConditionScope(for: stateA).isEqual(Self.nestedConditionScope(for: stateB)))
    }

    @Test
    func nestedConditionDifferentInnerBranchesAreNotEqual() {
        var stateA = AppState()
        stateA.rootForm.bookToModalPresent = 5 // takes the `else` inner branch -> BookScope

        var stateB = AppState()
        stateB.rootForm.bookToModalPresent = 150 // takes the `if` inner branch -> AlternateBookScope

        #expect(!Self.nestedConditionScope(for: stateA).isEqual(Self.nestedConditionScope(for: stateB)))
    }

    @Test
    func nestedConditionSameInnerBranchDifferentValueIsNotEqual() {
        var stateA = AppState()
        stateA.rootForm.bookToModalPresent = 150

        var stateB = AppState()
        stateB.rootForm.bookToModalPresent = 151

        #expect(!Self.nestedConditionScope(for: stateA).isEqual(Self.nestedConditionScope(for: stateB)))
    }
}
