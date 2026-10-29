//===--- FeatureLinksTests.swift ----------------------------------===//
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

@Suite("Feature links")
struct FeatureLinksTests {
    @MainActor
    @Test("A stack root registers the link routing of a single-screen feature")
    func stackRootRegistersSingleScreenFeatureLinkRouting() {
        let root = Text("Root")
            .navigationDestinations(for: FirstFeatureState<LinkHostState>.self)

        #expect(
            ObjectIdentifier(type(of: root))
                == ObjectIdentifier(ModifiedContent<Text, GlobalRoutingModifier<FirstLinkRouting>>.self)
        )
    }

    @MainActor
    @Test("A stack root registers a link routing together with the feature's other routings")
    func stackRootRegistersLinkRoutingWithOtherRoutings() {
        let root = Text("Root")
            .navigationDestinations(for: SecondFeatureState<LinkHostState>.self)

        #expect(
            ObjectIdentifier(type(of: root))
                == ObjectIdentifier(
                    ModifiedContent<Text, ModifiedContent<GlobalRoutingModifier<SecondRouting>, GlobalRoutingModifier<SecondLinkRouting>>>.self
                )
        )
    }

    @MainActor
    @Test("A feature pushes its own link onto the navigation path")
    func featurePushesItsOwnLinkOntoNavigationPath() {
        var path = NavigationPath()
        let router = GlobalRouter(path: Binding(get: { path }, set: { path = $0 }))

        router.navigate(for: FirstLinkRouting.self, to: .details(id: 1))

        #expect(path == NavigationPath([FirstLink.details(id: 1)]))
    }

    @Test("An app navigation action carries links of several features as one path")
    func appNavigationActionCarriesLinksOfSeveralFeatures() async {
        let store = await TestStore(initial: LinkHostState())

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

// MARK: - Feature fixtures

private struct LinkHostState: AppReducer {
    var first = FirstFeatureState<LinkHostState>()
    var second = SecondFeatureState<LinkHostState>()
    var navigation = NavigationForm()
}

private struct FirstFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    static var destinations: some ViewModifier {
        FirstLinkRouting.self
    }

    static func registerMiddlewares(in store: any Store<Host>) -> [MiddlewareWrapper<Host>] {}

    static func entryPoint(input: Void) -> EmptyView {
        EmptyView()
    }
}

private struct SecondFeatureState<Host: AppReducer>: FeatureState {
    typealias AppState = Host
    typealias FeatureRouting = EmptyRouting

    static var destinations: some ViewModifier {
        SecondRouting.self
        SecondLinkRouting.self
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
