
@testable import UDF
import UDFSwiftTesting
import Testing
import SwiftUI

@TestStoreActor
struct FormValueReferenceTests {
    struct AppState: AppReducer {
        var dataForm = DataForm()
    }

    struct DataForm: UDF.Form {
        var title: String = ""
        var count: Int = 0
    }

    /// Extracts the first `InternalAction` from a dispatched action (expected to be an `ActionGroup`).
    private static func unwrapInternalAction(from action: any Action) throws -> InternalAction {
        let group: ActionGroup = try #require(action as? ActionGroup)
        return try #require(group._actions.first)
    }

    // MARK: - Test Action
    struct TestAction: Action {
        var value: String
    }

    // MARK: - Modifier Permutations
    enum ModifierPermutation: CaseIterable {
        case animationDelaySilent
        case animationSilentDelay
        case delayAnimationSilent
        case delaySilentAnimation
        case silentAnimationDelay
        case silentDelayAnimation

        func apply(to ref: FormValueReference<DataForm, String>) -> Binding<String> {
            switch self {
            case .animationDelaySilent: (ref.with(animation: .linear).with(delay: 0.5).silent() as Binding)
            case .animationSilentDelay: (ref.with(animation: .linear).silent().with(delay: 0.5) as Binding)
            case .delayAnimationSilent: (ref.with(delay: 0.5).with(animation: .linear).silent() as Binding)
            case .delaySilentAnimation: (ref.with(delay: 0.5).silent().with(animation: .linear) as Binding)
            case .silentAnimationDelay: (ref.silent().with(animation: .linear).with(delay: 0.5) as Binding)
            case .silentDelayAnimation: (ref.silent().with(delay: 0.5).with(animation: .linear) as Binding)
            }
        }
    }

    @Test("with(animation:) returns FormValueReference, not Binding")
    func withAnimationReturnsSelf() {
        let store = TestStore(initial: AppState())
        let ref: FormValueReference<DataForm, String> = store.$state.dataForm.title
        let modified: FormValueReference<DataForm, String> = ref.with(animation: .linear)
        
        #expect(String(describing: type(of: modified)).contains("FormValueReference"))
    }

    @Test("with(delay:) returns FormValueReference, not Binding")
    func withDelayReturnsSelf() {
        let store = TestStore(initial: AppState())
        let ref: FormValueReference<DataForm, String> = store.$state.dataForm.title
        let modified: FormValueReference<DataForm, String> = ref.with(delay: 1.0)
        
        #expect(String(describing: type(of: modified)).contains("FormValueReference"))
    }

    @Test("silent() returns FormValueReference, not Binding")
    func silentReturnsSelf() {
        let store = TestStore(initial: AppState())
        let ref: FormValueReference<DataForm, String> = store.$state.dataForm.title
        let modified: FormValueReference<DataForm, String> = ref.silent()
        
        #expect(String(describing: type(of: modified)).contains("FormValueReference"))
    }

    @Test("with(animation:) returns Binding")
    func withAnimationReturnsBinding() {
        let store = TestStore(initial: AppState())
        let binding: Binding<String> = store.$state.dataForm.title.with(animation: .linear)
        
        #expect(String(describing: type(of: binding)).contains("Binding"))
    }

    @Test("with(delay:) returns Binding")
    func withDelayReturnsBinding() {
        let store = TestStore(initial: AppState())
        let binding: Binding<String> = store.$state.dataForm.title.with(delay: 1.0)
        
        #expect(String(describing: type(of: binding)).contains("Binding"))
    }

    @Test("silent() returns Binding")
    func silentReturnsBinding() {
        let store = TestStore(initial: AppState())
        let binding: Binding<String> = store.$state.dataForm.title.silent()
        
        #expect(String(describing: type(of: binding)).contains("Binding"))
    }

    @Test("Binding getter returns the current form field value")
    func bindingGetterReturnsCurrentValue() {
        let form = DataForm(title: "Hello")
        let store = TestStore(initial: AppState(dataForm: form))
        let binding: Binding<String> = store.$state.dataForm.title
        
        #expect(binding.wrappedValue == "Hello")
    }

    @Test("Binding setter updates state through the store")
    func bindingSetterUpdatesState() async {
        let store = TestStore(initial: AppState())
        let binding: Binding<String> = store.$state.dataForm.title

        binding.wrappedValue = "updated"
        store.wait()
        
        let success = store.state.dataForm.title == "updated"
        #expect(success)
    }

    @Test("with(delay:) binding updates state after delay")
    func withDelayUpdatesStateAfterDelay() async {
        let store = TestStore(initial: AppState())
        let binding: Binding<String> = store.$state.dataForm.title.with(delay: 0.5)

        binding.wrappedValue = "delayed"
        
        #expect(store.state.dataForm.title == "")
        
        store.wait(additionalSleepFor: 0.5)
        
        let success = store.state.dataForm.title == "delayed"
        #expect(success)
    }

    @Test("silent() binding updates state silently")
    func silentUpdatesState() async {
        let store = TestStore(initial: AppState())
        let binding: Binding<String> = store.$state.dataForm.title.silent()

        binding.wrappedValue = "silent"
        store.wait()
        
        let success = store.state.dataForm.title == "silent"
        #expect(success)
    }

    @Test(
        "All permutations of animation + delay + silent produce identical state updates",
        arguments: ModifierPermutation.allCases
    )
    func modifierOrderIndependence(permutation: ModifierPermutation) async {
        let store = TestStore(initial: AppState())
        let ref: FormValueReference<DataForm, String> = store.$state.dataForm.title
        
        let binding = permutation.apply(to: ref)
        binding.wrappedValue = "permutation"
        
        store.wait()
        
        let success = store.state.dataForm.title == "permutation"
        #expect(success)
    }
}
