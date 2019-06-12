import SwiftUI
import Combine
import CombineFeedback

class SignUpViewModel: BindableObject {

    let didChange = PassthroughSubject<Void, Never>()
    let input = PassthroughSubject<Event, Never>()
    private var cancelable: Cancellable? = nil

    private(set) var state: State

    init() {
        state = State()
        cancelable = Publishers.system(
            initial: state,
            feedbacks: [
                Feedback(effects: { _ in self.input.eraseToAnyPublisher() })
            ],
            reduce: SignUpViewModel.reduce
        ).sink { [weak self] state in
            self?.state = state
            dump(self?.state)
            self?.didChange.send(())
        }
    }

    deinit {
        didChange.send(completion: .finished)
        input.send(completion: .finished)
        cancelable?.cancel()
    }

    struct State {
        var email: String
        var password: String
        var passwordConfirmation: String

        init(
            email: String = "",
            password: String = "",
            passwordConfirmation: String = ""
        ) {
            self.email = email
            self.password = email
            self.passwordConfirmation = passwordConfirmation
        }

        var isSignUpButtonVisible: Bool {
            return !email.isEmpty
        }

        var isSignUpButtonEnabled: Bool {
            return !email.isEmpty &&
                !password.isEmpty &&
                password == passwordConfirmation
        }

        @discardableResult func with(_ block: (inout State) -> Void) -> State {
            var copy = self
            block(&copy)
            return copy
        }
    }

    enum Event {
        case ui(Action)
    }

    enum Action {
        case didChangeEmail(String)
        case didChangePassword(String)
        case didChangePasswordConfirmation(String)
    }

    func binding<T>(
        _ keyPath: KeyPath<SignUpViewModel.State, T>,
        action: @escaping (T) -> Action
    ) -> Binding<T> {

        return Binding<T>(
            getValue: { self.state[keyPath: keyPath] },
            setValue: { value in self.sendAction(action(value))  }
        )
    }

    func sendAction(_ action: Action) {
        input.send(.ui(action))
    }

    private static func reduce(state: State, event: Event) -> State {
        switch event {
        case let .ui(action):
            switch action {
            case let .didChangeEmail(email):
                return state.with {
                    $0.email = email
                }
            case let .didChangePassword(password):
                return state.with {
                    $0.password = password
                }
            case let .didChangePasswordConfirmation(confirmation):
                return state.with {
                    $0.passwordConfirmation = confirmation
                }
            }
        }
    }
}
