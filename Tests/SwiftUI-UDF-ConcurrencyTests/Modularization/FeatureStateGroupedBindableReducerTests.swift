//===--- FeatureStateGroupedBindableReducerTests.swift ------------===//
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

/// Covers `@BindableReducer` properties grouped inside a plain `Reducible` struct, which a `FeatureState`
/// mounts as a single property. The group is generic over its container so one group type can serve
/// several screens, and it nests a second group to cover bindable reducers two levels below the feature.
@TestStoreActor
@Suite("Bindable reducers grouped in a Reducible inside a FeatureState")
struct FeatureStateGroupedBindableReducerTests {
    private typealias Container = ArticleContainer<AppState>
    private typealias PreviewContainer = ArticlePreviewContainer<AppState>

    @Test("Loading a container creates its reducers in every bindable of the group, unloading releases them")
    func loadAndUnloadManageEveryBindableInGroup() async {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        var screen = store.state.articles.screen
        #expect(screen.form.reducers.count == 2)
        #expect(screen.flow.reducers.count == 2)
        #expect(screen.comments.form.reducers.count == 2)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: Container.self, id: first))

        screen = store.state.articles.screen
        #expect(screen.form.reducers[first] == nil)
        #expect(screen.flow.reducers[first] == nil)
        #expect(screen.comments.form.reducers[first] == nil)
        #expect(screen.form.reducers[second] != nil)
        #expect(screen.flow.reducers[second] != nil)
        #expect(screen.comments.form.reducers[second] != nil)
    }

    @Test("Binded actions mutate only the targeted instance across the group and its nested group")
    func bindedActionsMutateOnlyTargetedInstance() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        await store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "First")
                Actions.UpdateFormField(keyPath: \CommentsForm.draft, value: "Nice read")
                Actions.LoadArticle()
            }
            .binded(to: Container.self, by: first)
        )

        let screen = store.state.articles.screen

        let firstForm = try #require(screen.form.reducers[first])
        let secondForm = try #require(screen.form.reducers[second])
        #expect(firstForm.title == "First")
        #expect(secondForm.title.isEmpty)

        let firstComments = try #require(screen.comments.form.reducers[first])
        let secondComments = try #require(screen.comments.form.reducers[second])
        #expect(firstComments.draft == "Nice read")
        #expect(secondComments.draft.isEmpty)

        #expect(screen.flow.reducers[first] == ArticleFlow.loading)
        #expect(screen.flow.reducers[second] == ArticleFlow.none)
    }

    @Test("The group's regular reducers receive each binded action exactly once, unwrapped")
    func groupRegularReducersReceiveUnwrappedActionOnce() async throws {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions.OpenArticle().binded(to: Container.self, by: id))
        await store.dispatch(Actions.OpenArticle())

        let screen = store.state.articles.screen
        #expect(screen.visits.count == 2)
        #expect(screen.comments.visits.count == 2)

        let form = try #require(screen.form.reducers[id])
        #expect(form.openedCount == 1)
    }

    @Test("One group type reused for two containers stays isolated by container type")
    func reusedGroupStaysIsolatedByContainerType() async throws {
        let store = TestStore(initial: AppState())
        let id = Article.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: PreviewContainer.self, id: id))

        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ArticleForm.title, value: "Preview")
                .binded(to: PreviewContainer.self, by: id)
        )

        let screenForm = try #require(store.state.articles.screen.form.reducers[id])
        let previewForm = try #require(store.state.articles.preview.form.reducers[id])
        #expect(screenForm.title.isEmpty)
        #expect(previewForm.title == "Preview")

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: PreviewContainer.self, id: id))

        #expect(store.state.articles.preview.form.reducers[id] == nil)
        #expect(store.state.articles.preview.comments.form.reducers[id] == nil)
        #expect(store.state.articles.screen.form.reducers[id] != nil)
        #expect(store.state.articles.screen.comments.form.reducers[id] != nil)
    }

    @Test("A projected binding through the feature and group dispatches to the selected instance only")
    func projectedBindingThroughGroupTargetsSelectedInstance() async throws {
        let store = TestStore(initial: AppState())
        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))

        let feature: ReducerReference<AppState, ArticlesFeatureState<AppState>> = store.$state.articles
        let screen: ReducerReference<AppState, ArticleScreenReducers<Container>> = feature.screen
        let comments: ReducerReference<AppState, CommentsReducers<Container>> = screen.comments
        let commentForms: BindableReducerReference<AppState, Article.ID, CommentsForm> = comments.form
        (commentForms[second].draft as Binding<String>).wrappedValue = "Edited"
        store.wait()

        let firstComments = try #require(store.state.articles.screen.comments.form.reducers[first])
        let secondComments = try #require(store.state.articles.screen.comments.form.reducers[second])
        #expect(firstComments.draft.isEmpty)
        #expect(secondComments.draft == "Edited")
    }

    @Test("Feature middleware observes grouped bindable flows and loads data for each requested instance")
    func featureMiddlewareLoadsGroupedInstances() async throws {
        let store = TestStore(initial: AppState())
        await store.subscribe { store in
            return ArticlesFeatureState<AppState>.registerMiddlewares(in: store)
        }

        let first = Article.ID(value: 1)
        let second = Article.ID(value: 2)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: first))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: Container.self, id: second))
        await store.dispatch(Actions.LoadArticle().binded(to: Container.self, by: second))
        store.wait()

        let screen = store.state.articles.screen
        #expect(screen.form.reducers[first]?.article == nil)
        #expect(screen.form.reducers[second]?.article == second)
        #expect(screen.flow.reducers[second] == ArticleFlow.none)
        #expect(store.state.allArticles.byId[second]?.title == "Article 2")
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

private protocol ArticlesFeature: AppReducer {
    var allArticles: AllArticles { get }
    var articles: ArticlesFeatureState<Self> { get }
}

private struct ArticlesFeatureState<AppState: ArticlesFeature>: FeatureState {
    typealias FeatureRouting = EmptyRouting

    var screen = ArticleScreenReducers<ArticleContainer<AppState>>()
    var preview = ArticleScreenReducers<ArticlePreviewContainer<AppState>>()

    static func entryPoint(input: Article.ID) -> ArticleContainer<AppState> {
        ArticleContainer(id: input)
    }

    static func registerMiddlewares(in store: any Store<AppState>) -> [MiddlewareWrapper<AppState>] {
        ArticleMiddleware<AppState>.self
    }
}

/// Groups everything one article screen owns per instance, next to a regular reducer shared by all of them.
private struct ArticleScreenReducers<Container: BindableContainer>: Reducible {
    var visits = VisitCounter()

    @BindableReducer(ArticleForm.self, bindedTo: Container.self)
    var form

    @BindableReducer(ArticleFlow.self, bindedTo: Container.self)
    var flow

    var comments = CommentsReducers<Container>()
}

/// A second-level group, so bindable reducers sit two levels below the feature state.
private struct CommentsReducers<Container: BindableContainer>: Reducible {
    var visits = VisitCounter()

    @BindableReducer(CommentsForm.self, bindedTo: Container.self)
    var form
}

private struct VisitCounter: Reducible {
    var count = 0

    mutating func reduce(_ action: some Action) {
        if action is Actions.OpenArticle {
            count += 1
        }
    }
}

private struct ArticleForm: UDF.Form {
    var title = ""
    var article: Article.ID?
    var openedCount = 0

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

private struct CommentsForm: UDF.Form {
    var draft = ""
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
        state.articles.screen.form[id]
        state.articles.screen.flow[id]
        state.articles.screen.comments.form[id]
    }

    func map(store: EnvironmentStore<AppState>) -> EmptyComponent.Props {
        .init()
    }
}

private struct ArticlePreviewContainer<AppState: ArticlesFeature>: BindableContainer {
    typealias ContainerComponent = EmptyComponent

    let id: Article.ID

    func scope(for state: AppState) -> Scope {
        state.articles.preview.form[id]
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
        state.articles.screen.flow
    }

    func observe(state: AppState) {
        for (id, flow) in state.articles.screen.flow where flow == .loading {
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

private struct AppState: AppReducer, ArticlesFeature {
    var allArticles = AllArticles()
    var articles = ArticlesFeatureState<AppState>()
}

private struct EmptyComponent: Component {
    struct Props {}

    var props: Props

    var body: some View {
        EmptyView()
    }
}
