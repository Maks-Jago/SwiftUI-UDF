//===--- BindableFeatureStateTests.swift --------------------------===//
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
import UDFSwiftTesting

/// Covers a `FeatureState` mounted in the app state through `@BindableReducer`, so every instance of the
/// feature's entry container owns a whole copy of the feature state, nested forms and flows included.
@TestStoreActor
@Suite("FeatureState mounted as a bindable reducer")
struct BindableFeatureStateTests {
    private typealias Container = ArticleContainer<AppState>

    @Test("Loading containers creates a whole feature state per ID, unloading releases it")
    func loadAndUnloadManageWholeFeatureState() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        #expect(store.state.article.reducers.count == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        #expect(store.state.article.reducers.count == 2)

        let feature = try #require(store.state.article.reducers[first])
        #expect(feature == ArticleFeatureState<AppState>())

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: first))

        #expect(store.state.article.reducers[first] == nil)
        #expect(store.state.article.reducers[second] != nil)
    }

    @Test("A feature instance stays alive until the last container with the same ID unloads")
    func referenceCountingForWholeFeatureState() async {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "Shared")
                .binded(to: Container.self, by: id)
        )

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: id))
        #expect(store.state.article.reducers[id]?.form.title == "Shared")

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: id))
        #expect(store.state.article.reducers[id] == nil)
    }

    @Test("Binded actions reach the feature's own reduce and its nested reducers for the bound instance only")
    func bindedActionsReachOnlyBoundFeatureInstance() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        await store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "First")
                Actions.LoadArticle()
            }
            .binded(to: Container.self, by: first)
        )

        let firstFeature = try #require(store.state.article.reducers[first])
        let secondFeature = try #require(store.state.article.reducers[second])

        #expect(firstFeature.loadRequests == 1)
        #expect(firstFeature.form.title == "First")
        #expect(firstFeature.flow == .loading)

        #expect(secondFeature == ArticleFeatureState<AppState>())
    }

    @Test("Unbound actions skip every feature instance")
    func unboundActionsSkipFeatureInstances() async throws {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions.LoadArticle())
        await store.dispatch(Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "Unbound"))

        let feature = try #require(store.state.article.reducers[id])
        #expect(feature == ArticleFeatureState<AppState>())
    }

    @Test("Each binded action is reduced exactly once by the feature and by every reducer nested in it")
    func bindedActionReducedOncePerNestedReducer() async throws {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions.OpenArticle().binded(to: Container.self, by: id))

        let feature = try #require(store.state.article.reducers[id])
        #expect(feature.openedCount == 1)

        // `RuntimeReducing.bindableReduce` walks the bound reducer's properties twice, so every reducer
        // nested in it reduces a binded action twice. Remove the wrapper once that is fixed.
        withKnownIssue("Reducers nested in a bindable reducer reduce each binded action twice") {
            #expect(feature.form.openedCount == 1)
            #expect(feature.form.stats.openedCount == 1)
        }
    }

    @Test("A binded action reaches root storage unwrapped and the bound feature instance wrapped")
    func bindedActionReachesStorageAndBoundInstance() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)
        let article = Article(id: first, title: "Loaded")

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        await store.dispatch(
            Actions.DidLoadItem(item: article, id: ArticleFlow.id)
                .binded(to: Container.self, by: first)
        )

        #expect(store.state.allArticles.byId[first] == article)
        #expect(store.state.article.reducers[first]?.form.article == first)
        #expect(store.state.article.reducers[second]?.form.article == nil)
    }

    @Test("A projected binding into a feature instance's nested form dispatches to that instance only")
    func projectedBindingIntoFeatureInstanceTargetsSelectedInstance() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        let features: BindableReducerReference<AppState, Article.ID, ArticleFeatureState<AppState>> = store.$state.article
        let form: ReducerReference<AppState, ArticleForm> = features[second].form
        (form.title as Binding<String>).wrappedValue = "Edited"
        store.wait()

        #expect(store.state.article.reducers[first]?.form.title == "")
        #expect(store.state.article.reducers[second]?.form.title == "Edited")
    }

    @Test("Explicitly subscribed feature middleware loads data for each requested feature instance")
    func featureMiddlewareLoadsPerFeatureInstance() async throws {
        let store = TestStore(initial: AppState())
        await store.subscribe { store in
            return ArticleFeatureState<AppState>.registerMiddlewares(in: store)
        }

        let ids = (1...3).map(Article.ID.init(value:))
        for id in ids {
            await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        }

        await store.dispatch(
            ActionGroup {
                Actions.LoadArticle().binded(to: Container.self, by: ids[0])
                Actions.LoadArticle().binded(to: Container.self, by: ids[2])
            }
        )
        store.wait()

        #expect(store.state.article.reducers[ids[0]]?.form.article == ids[0])
        #expect(store.state.article.reducers[ids[1]]?.form.article == nil)
        #expect(store.state.article.reducers[ids[2]]?.form.article == ids[2])

        for id in ids {
            #expect(store.state.article.reducers[id]?.flow == ArticleFlow.none)
        }

        #expect(store.state.allArticles.byId.count == 2)
    }
}

// MARK: - Actions

private extension Actions {
    struct LoadArticle: Action {}
    struct OpenArticle: Action {}
}

// MARK: - Models

private struct Article: Hashable, Identifiable, Sendable {
    struct ID: Hashable, Sendable {
        var value: Int
    }

    var id: ID
    var title: String
}

// MARK: - Feature module

private protocol ArticleFeature: AppReducer {
    var allArticles: AllArticles { get }
    var article: BindableReducer<Article.ID, ArticleFeatureState<Self>> { get }
}

private struct ArticleFeatureState<AppState: ArticleFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting

    var form = ArticleForm()
    var flow = ArticleFlow()
    var loadRequests = 0
    var openedCount = 0

    mutating func reduce(_ action: some Action) {
        switch action {
        case is Actions.LoadArticle:
            loadRequests += 1

        case is Actions.OpenArticle:
            openedCount += 1

        default:
            break
        }
    }

    static func entryPoint(input: Article.ID) -> ArticleContainer<AppState> {
        ArticleContainer(id: input)
    }

    static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
        ArticleMiddleware<AppState>.self
    }
}

private struct ArticleForm: UDF.Form {
    var title = ""
    var article: Article.ID?
    var openedCount = 0
    var stats = ArticleStats()

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidLoadItem<Article> where action.id == ArticleFlow.id:
            article = action.item.id

        case is Actions.OpenArticle:
            openedCount += 1

        default:
            break
        }
    }
}

private struct ArticleStats: Reducible {
    var openedCount = 0

    mutating func reduce(_ action: some Action) {
        if action is Actions.OpenArticle {
            openedCount += 1
        }
    }
}

private enum ArticleFlow: IdentifiableFlow {
    case none
    case loading

    init() {
        self = .none
    }

    mutating func reduce(_ action: some Action) {
        switch action {
        case is Actions.LoadArticle:
            self = .loading

        case let action as Actions.DidLoadItem<Article> where action.id == Self.id:
            self = .none

        default:
            break
        }
    }
}

private struct ArticleContainer<AppState: ArticleFeature>: BindableContainer {
    typealias ContainerComponent = EmptyComponent

    let id: Article.ID

    func scope(for state: AppState) -> Scope {
        state.article[id]
    }

    func map(store: EnvironmentStore<AppState>) -> EmptyComponent.Props {
        .init()
    }
}

private final class ArticleMiddleware<AppState: ArticleFeature>: Middleware<AppState>, @unchecked Sendable {
    enum Cancellation: Hashable {
        case loadArticle(Article.ID)
    }

    struct Environment: Sendable {
        var loadArticle: @Sendable (_ id: Article.ID) async throws -> Article
    }

    var environment: Environment!

    static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
        Environment { id in Article(id: id, title: "Live article \(id.value)") }
    }

    static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
        Environment { id in Article(id: id, title: "Article \(id.value)") }
    }

    func scope(for state: AppState) -> Scope {
        state.article
    }

    func observe(state: AppState) {
        for (id, feature) in state.article where feature.flow == .loading {
            execute(flowId: ArticleFlow.id, cancellation: Cancellation.loadArticle(id)) { flowId in
                let article = try await self.environment.loadArticle(id)
                return Actions.DidLoadItem(item: article, id: flowId)
                    .binded(to: ArticleContainer<AppState>.self, by: id)
            }
        }
    }
}

// MARK: - App composition

private struct AllArticles: Reducible {
    var byId: [Article.ID: Article] = [:]

    mutating func reduce(_ action: some Action) {
        if let action = action as? Actions.DidLoadItem<Article> {
            byId[action.item.id] = action.item
        }
    }
}

private struct AppState: AppReducer, ArticleFeature {
    var allArticles = AllArticles()

    @BindableReducer(ArticleFeatureState<AppState>.self, bindedTo: ArticleContainer<AppState>.self)
    var article
}

private struct EmptyComponent: Component {
    struct Props {}

    var props: Props

    var body: some View {
        EmptyView()
    }
}
