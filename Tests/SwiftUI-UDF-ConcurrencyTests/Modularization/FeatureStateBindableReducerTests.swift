//===--- FeatureStateBindableReducerTests.swift -------------------===//
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

/// Covers `@BindableReducer` properties declared directly inside a `FeatureState`, the regular way a
/// feature module owns per-instance state for its `BindableContainer`s.
@TestStoreActor
@Suite("Bindable reducers declared inside a FeatureState")
struct FeatureStateBindableReducerTests {
    private typealias Container = ArticleContainer<AppState>

    @Test("Loading containers creates per-ID reducers inside the feature, unloading releases them")
    func loadAndUnloadManageReducersInsideFeature() async {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        #expect(store.state.articles.articleForm.reducers.count == 0)
        #expect(store.state.articles.articleFlow.reducers.count == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        #expect(store.state.articles.articleForm.reducers.count == 2)
        #expect(store.state.articles.articleFlow.reducers.count == 2)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: first))

        #expect(store.state.articles.articleForm.reducers[first] == nil)
        #expect(store.state.articles.articleFlow.reducers[first] == nil)
        #expect(store.state.articles.articleForm.reducers[second] != nil)
        #expect(store.state.articles.articleFlow.reducers[second] != nil)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: second))

        #expect(store.state.articles.articleForm.reducers.count == 0)
        #expect(store.state.articles.articleFlow.reducers.count == 0)
    }

    @Test("Reducers inside the feature stay alive until the last container with the same ID unloads")
    func referenceCountingInsideFeature() async {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "Shared")
                .binded(to: Container.self, by: id)
        )

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: id))
        #expect(store.state.articles.articleForm.reducers[id]?.title == "Shared")

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: id))
        #expect(store.state.articles.articleForm.reducers[id] == nil)
    }

    @Test("Binded actions mutate only the targeted instance inside the feature")
    func bindedActionsMutateOnlyTargetedInstance() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "First")
                .binded(to: Container.self, by: first)
        )
        await store.dispatch(Actions.LoadArticle().binded(to: Container.self, by: second))

        let firstForm = try #require(store.state.articles.articleForm.reducers[first])
        let secondForm = try #require(store.state.articles.articleForm.reducers[second])
        #expect(firstForm.title == "First")
        #expect(secondForm.title.isEmpty)

        #expect(store.state.articles.articleFlow.reducers[first] == ArticleFlow.none)
        #expect(store.state.articles.articleFlow.reducers[second] == ArticleFlow.loading)
    }

    @Test("Unbound actions skip bindable instances but still reach the feature's regular reducers")
    func unboundActionsReachOnlyRegularReducers() async throws {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions.MarkArticleSeen())
        await store.dispatch(Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "Unbound"))

        let form = try #require(store.state.articles.articleForm.reducers[id])
        #expect(form.seenCount == 0)
        #expect(form.title.isEmpty)
        #expect(store.state.articles.feed.seenCount == 1)
    }

    @Test("A binded action reaches its instance and is unwrapped once for root storage and feature reducers")
    func bindedActionIsUnwrappedForSharedReducers() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)
        let article = Article(id: first, title: "Loaded")

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        await store.dispatch(
            ActionGroup {
                Actions.DidLoadItem(item: article, id: ArticleFlow.id)
                Actions.MarkArticleSeen()
            }
            .binded(to: Container.self, by: first)
        )

        #expect(store.state.allArticles.byId[first] == article)
        #expect(store.state.articles.feed.seenCount == 1)

        let firstForm = try #require(store.state.articles.articleForm.reducers[first])
        #expect(firstForm.article == first)
        #expect(firstForm.seenCount == 1)

        let secondForm = try #require(store.state.articles.articleForm.reducers[second])
        #expect(secondForm.article == nil)
        #expect(secondForm.seenCount == 0)
    }

    @Test("A projected binding through the feature dispatches to the selected instance only")
    func projectedBindingThroughFeatureTargetsSelectedInstance() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        let feature: ReducerReference<AppState, ArticlesFeatureState<AppState>> = store.$state.articles
        let forms: BindableReducerReference<AppState, Article.ID, ArticleForm> = feature.articleForm
        (forms[second].title as Binding<String>).wrappedValue = "Edited"
        store.wait()

        let firstForm = try #require(store.state.articles.articleForm.reducers[first])
        let secondForm = try #require(store.state.articles.articleForm.reducers[second])
        #expect(firstForm.title.isEmpty)
        #expect(secondForm.title == "Edited")
    }

    @Test("Feature middleware observes bindable flows and loads data for each requested instance")
    func featureMiddlewareLoadsPerInstance() async throws {
        let store = TestStore(initial: AppState())
        await store.subscribe { store in
            return ArticlesFeatureState<AppState>.registerMiddlewares(in: store)
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

        #expect(store.state.articles.articleForm.reducers[ids[0]]?.article == ids[0])
        #expect(store.state.articles.articleForm.reducers[ids[1]]?.article == nil)
        #expect(store.state.articles.articleForm.reducers[ids[2]]?.article == ids[2])

        for id in ids {
            #expect(store.state.articles.articleFlow.reducers[id] == ArticleFlow.none)
        }

        #expect(store.state.allArticles.byId.count == 2)
    }

    @Test("Two features binding the same reducer type and ID stay isolated by container type")
    func twoFeaturesWithSameReducerTypeStayIsolated() async throws {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ReadingListContainer<AppState>.self, id: id))

        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "Reading list")
                .binded(to: ReadingListContainer<AppState>.self, by: id)
        )

        let articleForm = try #require(store.state.articles.articleForm.reducers[id])
        let readingListForm = try #require(store.state.readingList.articleForm.reducers[id])
        #expect(articleForm.title.isEmpty)
        #expect(readingListForm.title == "Reading list")

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: id))

        #expect(store.state.articles.articleForm.reducers[id] == nil)
        #expect(store.state.readingList.articleForm.reducers[id] != nil)
    }
}

// MARK: - Actions

private extension Actions {
    struct LoadArticle: Action {}
    struct MarkArticleSeen: Action {}
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

private protocol ArticlesFeature: AppReducer {
    var allArticles: AllArticles { get }
    var articles: ArticlesFeatureState<Self> { get }
}

private struct ArticlesFeatureState<AppState: ArticlesFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting

    var feed = ArticlesFeedForm()

    @BindableReducer(ArticleForm.self, bindedTo: ArticleContainer<AppState>.self)
    var articleForm

    @BindableReducer(ArticleFlow.self, bindedTo: ArticleContainer<AppState>.self)
    var articleFlow

    static func entryPoint(input: Article.ID) -> ArticleContainer<AppState> {
        ArticleContainer(id: input)
    }

    static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
        ArticleMiddleware<AppState>.self
    }
}

private struct ArticlesFeedForm: UDF.Form {
    var seenCount = 0

    mutating func reduce(_ action: some Action) {
        if action is Actions.MarkArticleSeen {
            seenCount += 1
        }
    }
}

private struct ArticleForm: UDF.Form {
    var title = ""
    var article: Article.ID?
    var seenCount = 0

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidLoadItem<Article> where action.id == ArticleFlow.id:
            article = action.item.id

        case is Actions.MarkArticleSeen:
            seenCount += 1

        default:
            break
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

private struct ArticleContainer<AppState: ArticlesFeature>: BindableContainer {
    typealias ContainerComponent = EmptyComponent

    let id: Article.ID

    func scope(for state: AppState) -> Scope {
        state.articles.articleForm[id]
        state.articles.articleFlow[id]
    }

    func map(store: EnvironmentStore<AppState>) -> EmptyComponent.Props {
        .init()
    }
}

private final class ArticleMiddleware<AppState: ArticlesFeature>: Middleware<AppState>, @unchecked Sendable {
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
        state.articles.articleFlow
    }

    func observe(state: AppState) {
        for (id, flow) in state.articles.articleFlow where flow == .loading {
            execute(flowId: ArticleFlow.id, cancellation: Cancellation.loadArticle(id)) { flowId in
                let article = try await self.environment.loadArticle(id)
                return Actions.DidLoadItem(item: article, id: flowId)
                    .binded(to: ArticleContainer<AppState>.self, by: id)
            }
        }
    }
}

// MARK: - Second feature reusing the same reducer type

private protocol ReadingListFeature: AppReducer {
    var readingList: ReadingListFeatureState<Self> { get }
}

private struct ReadingListFeatureState<AppState: ReadingListFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting

    @BindableReducer(ArticleForm.self, bindedTo: ReadingListContainer<AppState>.self)
    var articleForm

    static func entryPoint(input: Article.ID) -> ReadingListContainer<AppState> {
        ReadingListContainer(id: input)
    }

    static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {}
}

private struct ReadingListContainer<AppState: ReadingListFeature>: BindableContainer {
    typealias ContainerComponent = EmptyComponent

    let id: Article.ID

    func scope(for state: AppState) -> Scope {
        state.readingList.articleForm[id]
    }

    func map(store: EnvironmentStore<AppState>) -> EmptyComponent.Props {
        .init()
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

private struct AppState: AppReducer, ArticlesFeature, ReadingListFeature {
    var allArticles = AllArticles()
    var articles = ArticlesFeatureState<AppState>()
    var readingList = ReadingListFeatureState<AppState>()
}

private struct EmptyComponent: Component {
    struct Props {}

    var props: Props

    var body: some View {
        EmptyView()
    }
}
