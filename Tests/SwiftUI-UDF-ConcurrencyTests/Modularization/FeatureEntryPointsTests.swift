//===--- FeatureEntryPointsTests.swift ----------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI
import Testing
@testable import UDF

@Suite("Feature entry points")
struct FeatureEntryPointsTests {
    @Test("A feature's routing resolves an exit through the entry points the app provides")
    func routingResolvesExitThroughAppEntryPoints() {
        let screen = CatalogRouting<ExitHostState>().view(for: .itemDetails(7))

        #expect((screen as? ItemDetailsScreen)?.itemID == 7)
    }

    @Test("The app's entry points are the ones the feature state is mounted with")
    func featureStateIsMountedWithAppEntryPoints() {
        #expect(ObjectIdentifier(ExitHostState.CatalogEntryPoints.self) == ObjectIdentifier(AppCatalogEntryPoints.self))
    }
}

// MARK: - Exit fixtures

private enum ExitRoute {
    case itemDetails(Int)
}

private struct ItemDetailsScreen: View {
    let itemID: Int

    var body: some View {
        Text("Item \(itemID)")
    }
}

private protocol CatalogFeature: AppReducer {
    associatedtype CatalogEntryPoints: FeatureEntryPointProviding<ExitRoute>
}

private struct AppCatalogEntryPoints: FeatureEntryPointProviding {
    func view(for entryPoint: ExitRoute) -> some View {
        switch entryPoint {
        case let .itemDetails(id):
            ItemDetailsScreen(itemID: id)
        }
    }
}

private struct CatalogRouting<AppState: CatalogFeature>: Routing {
    func view(for route: ExitRoute) -> some View {
        AppState.CatalogEntryPoints().view(for: route)
    }
}

// MARK: - Feature fixtures

private struct ExitHostState: AppReducer, CatalogFeature {
    typealias CatalogEntryPoints = AppCatalogEntryPoints
}
