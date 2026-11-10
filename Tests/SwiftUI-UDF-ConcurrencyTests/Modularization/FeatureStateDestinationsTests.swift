//===--- FeatureStateDestinationsTests.swift ----------------------===//
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

@Suite("Feature state destinations")
struct FeatureStateDestinationsTests {
    @Test("Generic code reads each feature's own destinations")
    func genericCodeReadsEachFeaturesOwnDestinations() {
        func destinationsType<Feature: FeatureState>(of feature: Feature.Type) -> Any.Type {
            type(of: Feature.destinations)
        }

        #expect(
            ObjectIdentifier(destinationsType(of: FirstFeatureState<NavigationHostState>.self))
                == ObjectIdentifier(ModifiedContent<GlobalRoutingModifier<FirstRouting>, GlobalRoutingModifier<SecondRouting>>.self),
            "A feature with two routings registers both, in order"
        )
        #expect(
            ObjectIdentifier(destinationsType(of: SecondFeatureState<NavigationHostState>.self))
                == ObjectIdentifier(GlobalRoutingModifier<SecondRouting>.self),
            "A feature with one routing registers only that routing"
        )
        #expect(
            ObjectIdentifier(destinationsType(of: EmptyFeatureState<NavigationHostState>.self))
                == ObjectIdentifier(EmptyModifier.self),
            "A feature with no routings registers nothing"
        )
    }

    @MainActor
    @Test("A stack root registers a feature's destinations with one call")
    func stackRootRegistersFeatureDestinations() {
        let root = Text("Root")
            .navigationDestinations(for: FirstFeatureState<NavigationHostState>.self)

        #expect(
            ObjectIdentifier(type(of: root))
                == ObjectIdentifier(
                    ModifiedContent<Text, ModifiedContent<GlobalRoutingModifier<FirstRouting>, GlobalRoutingModifier<SecondRouting>>>.self
                )
        )
    }

    @MainActor
    @Test("A nonisolated entry point provider registers a feature's destinations")
    func nonisolatedContextRegistersFeatureDestinations() {
        let root = nonisolatedStackRoot()

        #expect(
            ObjectIdentifier(type(of: root))
                == ObjectIdentifier(
                    ModifiedContent<Text, ModifiedContent<GlobalRoutingModifier<FirstRouting>, GlobalRoutingModifier<SecondRouting>>>.self
                )
        )
    }
}

// MARK: - Routing fixtures

private struct FirstRouting: Routing {
    enum Route: Hashable {
        case details
    }

    func view(for route: Route) -> some View {
        EmptyView()
    }
}

private struct SecondRouting: Routing {
    enum Route: Hashable {
        case details
    }

    func view(for route: Route) -> some View {
        EmptyView()
    }
}

// MARK: - Feature fixtures

private struct NavigationHostState: AppReducer {
    var first = FirstFeatureState<NavigationHostState>()
    var second = SecondFeatureState<NavigationHostState>()
    var empty = EmptyFeatureState<NavigationHostState>()
}

private struct FirstFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host

    static var destinations: some ViewModifier {
        FirstRouting.self
        SecondRouting.self
    }

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct SecondFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host

    static var destinations: some ViewModifier {
        SecondRouting.self
    }

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct EmptyFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host

    static var destinations: some ViewModifier {}

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

// The app's entry point providers are nonisolated, so they must be able to register destinations too.
private nonisolated func nonisolatedStackRoot() -> some View {
    Text("Root")
        .navigationDestinations(for: FirstFeatureState<NavigationHostState>.self)
}
