//===--- NavigatingFeatureStateTests.swift ------------------------===//
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

@Suite("Navigating feature state")
struct NavigatingFeatureStateTests {
    @Test("Destinations register every listed routing in order")
    func destinationsRegisterListedRoutingsInOrder() {
        let destinations = FirstFeatureState<NavigationHostState>.destinations

        #expect(
            ObjectIdentifier(type(of: destinations))
                == ObjectIdentifier(ModifiedContent<RoutingDestination<FirstRouting>, RoutingDestination<SecondRouting>>.self)
        )
    }

    @Test("Destinations with a single routing register only that routing")
    func destinationsWithSingleRoutingRegisterOnlyThatRouting() {
        let destinations = SecondFeatureState<NavigationHostState>.destinations

        #expect(ObjectIdentifier(type(of: destinations)) == ObjectIdentifier(RoutingDestination<SecondRouting>.self))
    }

    @Test("Empty destinations register nothing")
    func emptyDestinationsRegisterNothing() {
        let destinations = EmptyFeatureState<NavigationHostState>.destinations

        #expect(ObjectIdentifier(type(of: destinations)) == ObjectIdentifier(EmptyModifier.self))
    }

    @Test("Generic code reads each feature's own destinations")
    func genericCodeReadsEachFeaturesOwnDestinations() {
        func destinationsType<Feature: NavigatingFeatureState>(of feature: Feature.Type) -> Any.Type {
            type(of: Feature.destinations)
        }

        #expect(
            ObjectIdentifier(destinationsType(of: FirstFeatureState<NavigationHostState>.self))
                == ObjectIdentifier(ModifiedContent<RoutingDestination<FirstRouting>, RoutingDestination<SecondRouting>>.self)
        )
        #expect(
            ObjectIdentifier(destinationsType(of: SecondFeatureState<NavigationHostState>.self))
                == ObjectIdentifier(RoutingDestination<SecondRouting>.self)
        )
        #expect(
            ObjectIdentifier(destinationsType(of: EmptyFeatureState<NavigationHostState>.self))
                == ObjectIdentifier(EmptyModifier.self)
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
                    ModifiedContent<Text, ModifiedContent<RoutingDestination<FirstRouting>, RoutingDestination<SecondRouting>>>.self
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

// MARK: - Navigating feature fixtures

private struct NavigationHostState: AppReducer {
    var first = FirstFeatureState<NavigationHostState>()
    var second = SecondFeatureState<NavigationHostState>()
    var empty = EmptyFeatureState<NavigationHostState>()
}

private struct FirstFeatureState<Host: AppReducer>: NavigatingFeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    static var destinations: some ViewModifier {
        FirstRouting.self
        SecondRouting.self
    }

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct SecondFeatureState<Host: AppReducer>: NavigatingFeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    static var destinations: some ViewModifier {
        SecondRouting.self
    }

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct EmptyFeatureState<Host: AppReducer>: NavigatingFeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    static var destinations: some ViewModifier {}

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}
