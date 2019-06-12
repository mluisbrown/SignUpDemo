import SwiftUI
import Combine
import CombineFeedback
import CryptoKit

struct SignUpError: Error {
    var localizedDescription: String {
        return "SignUp Failed. Please try again."
    }
}

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
                SignUpViewModel.whenSigningUp(),
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
        enum Status {
            case editing
            case signingUp
        }

        var status: Status = .editing
        var email: String = ""
        var password: String = ""
        var passwordConfirmation: String = ""
        var signUpErrorMessage: String? = nil

        init() {}

        var isSignUpButtonEnabled: Bool {
            return !email.isEmpty &&
                !password.isEmpty &&
                password == passwordConfirmation
        }

        var isSigningUp: Bool {
            switch self.status {
            case .signingUp:
                return true
            default:
                return false
            }
        }

        @discardableResult func with(_ block: (inout State) -> Void) -> State {
            var copy = self
            block(&copy)
            return copy
        }
    }

    enum Event {
        case ui(Action)
        case signUpFailed(SignUpError)
    }

    enum Action {
        case didChangeEmail(String)
        case didChangePassword(String)
        case didChangePasswordConfirmation(String)
        case didTapSignUp
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
            case .didTapSignUp:
                return state.with {
                    $0.signUpErrorMessage = nil
                    $0.status = .signingUp
                }
            }
        case let .signUpFailed(error):
            return state.with {
                $0.status = .editing
                $0.signUpErrorMessage = error.localizedDescription
            }
        }
    }

    private static func whenSigningUp() -> Feedback<State, Event> {
        return Feedback(predicate: { $0.isSigningUp }) { _ -> AnyPublisher<Event, Never> in
            return Publishers.Just(Event.signUpFailed(SignUpError()))
                .eraseToAnyPublisher()
        }
    }
}
