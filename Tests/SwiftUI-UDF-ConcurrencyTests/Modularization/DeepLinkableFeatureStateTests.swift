//===--- DeepLinkableFeatureStateTests.swift ----------------------===//
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

@Suite("Deep-linkable feature state")
struct DeepLinkableFeatureStateTests {
    @MainActor
    @Test("A stack root registers the link routing of a single-screen feature")
    func stackRootRegistersSingleScreenFeatureLinkRouting() {
        let root = Text("Root")
            .navigationDestinations(for: FirstFeatureState<DeepLinkHostState>.self)

        #expect(
            ObjectIdentifier(type(of: root))
                == ObjectIdentifier(ModifiedContent<ModifiedContent<Text, EmptyModifier>, RoutingDestination<FirstLinkRouting>>.self)
        )
    }

    @MainActor
    @Test("A stack root registers both destinations and link routing of a feature with several screens")
    func stackRootRegistersDestinationsAndLinkRouting() {
        let root = Text("Root")
            .navigationDestinations(for: SecondFeatureState<DeepLinkHostState>.self)

        #expect(
            ObjectIdentifier(type(of: root))
                == ObjectIdentifier(
                    ModifiedContent<ModifiedContent<Text, RoutingDestination<SecondRouting>>, RoutingDestination<SecondLinkRouting>>.self
                )
        )
    }

    @MainActor
    @Test("A feature pushes its own link onto the navigation path")
    func featurePushesItsOwnLinkOntoNavigationPath() {
        var path = NavigationPath()
        let router = GlobalRouter(path: Binding(get: { path }, set: { path = $0 }))

        router.navigate(for: FirstFeatureState<DeepLinkHostState>.LinkRouting.self, to: .details(id: 1))

        #expect(path == NavigationPath([FirstLink.details(id: 1)]))
    }

    @Test("An app navigation action carries links of several features as one path")
    func appNavigationActionCarriesLinksOfSeveralFeatures() async {
        let store = await TestStore(initial: DeepLinkHostState())

        await store.dispatch(
            Actions.NavigateResetStack(path: [SecondLink.section(id: 2), FirstLink.details(id: 1)])
        )

        var expectedPath = NavigationPath()
        expectedPath.append(SecondLink.section(id: 2))
        expectedPath.append(FirstLink.details(id: 1))

        let state = await store.state
        #expect(state.navigation.path == expectedPath)
    }
}

// MARK: - Link fixtures

private enum FirstLink: Hashable, Sendable {
    case details(id: Int)
}

private struct FirstLinkRouting: Routing {
    func view(for link: FirstLink) -> some View {
        EmptyView()
    }
}

private enum SecondLink: Hashable, Sendable {
    case section(id: Int)
}

private struct SecondLinkRouting: Routing {
    func view(for link: SecondLink) -> some View {
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

// MARK: - Deep-linkable feature fixtures

private struct DeepLinkHostState: AppReducer {
    var first = FirstFeatureState<DeepLinkHostState>()
    var second = SecondFeatureState<DeepLinkHostState>()
    var navigation = NavigationForm()
}

private struct FirstFeatureState<Host: AppReducer>: DeepLinkableFeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting
    typealias LinkRouting = FirstLinkRouting

    static var destinations: some ViewModifier {}

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct SecondFeatureState<Host: AppReducer>: DeepLinkableFeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting
    typealias LinkRouting = SecondLinkRouting

    static var destinations: some ViewModifier {
        SecondRouting.self
    }

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct NavigationForm: UDF.Form, @unchecked Sendable {
    var path = NavigationPath()

    mutating func reduce(_ action: some Action) {
        guard let action = action as? Actions.NavigateResetStack else {
            return
        }

        path = NavigationPath()
        for link in action.to {
            path.append(link)
        }
    }
}
