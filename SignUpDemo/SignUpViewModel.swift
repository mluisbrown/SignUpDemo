import SwiftUI
import Combine
import CombineFeedback

class SignUpViewModel: BindableObject {

    let didChange = PassthroughSubject<Void, Never>()
    let input = PassthroughSubject<Event, Never>()
    private var cancelable: Cancellable? = nil

    private(set) var state: State

    init(
        api: GravatarAPI = GravatarAPI.live
    ) {
        state = State()
        cancelable = Publishers.system(
            initial: state,
            feedbacks: [
                SignUpViewModel.whenSigningUp(api: api),
                Feedback(effects: { _ in self.input.eraseToAnyPublisher() })
            ],
            reduce: SignUpViewModel.reduce
        ).sink { [weak self] state in
            dump(state)
            self?.state = state
            self?.didChange.send(())
        }
    }

    deinit {
        didChange.send(completion: .finished)
        input.send(completion: .finished)
        cancelable?.cancel()
    }

    struct State: With {
        enum Status {
            case editing
            case signingUp
        }

        var status: Status = .editing
        var email: String = ""
        var password: String = ""
        var passwordConfirmation: String = ""
        var signUpErrorMessage: String? = nil
        var avatar: UIImage? = nil

        init() {}

        var isSignUpButtonEnabled: Bool {
            return !email.isEmpty &&
                !password.isEmpty &&
                password == passwordConfirmation &&
                status == .editing
        }

        var isSigningUp: Bool {
            switch self.status {
            case .signingUp:
                return true
            default:
                return false
            }
        }
    }

    enum Event {
        case ui(Action)
        case signUpFailed(SignUpError)
        case signUpSucceeded(UIImage)
    }

    enum Action {
        case didChangeEmail(String)
        case didChangePassword(String)
        case didChangePasswordConfirmation(String)
        case didTapSignUp
    }

    private func action<T>(
        for keyPath: KeyPath<SignUpViewModel.State, T>
    ) -> Optional<(T) -> Action> {
        switch keyPath {
        case \State.email:
            return Action.didChangeEmail as? (T) -> Action
        case \State.password:
            return Action.didChangePassword as? (T) -> Action
        case \State.passwordConfirmation:
            return Action.didChangePasswordConfirmation as? (T) -> Action
        default:
            return nil
        }
    }

    func binding<T>(
        _ keyPath: KeyPath<SignUpViewModel.State, T>
    ) -> Binding<T> {
        return Binding<T>(
            getValue: { self.state[keyPath: keyPath] },
            setValue: { value in
                if let action = self.action(for: keyPath) {
                    self.sendAction(action(value))
                }
            }
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
                    $0.signUpErrorMessage = nil
                    $0.avatar = nil
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
        case let .signUpSucceeded(image):
            return state.with {
                $0.status = .editing
                $0.avatar = image
            }
        case let .signUpFailed(error):
            return state.with {
                $0.status = .editing
                $0.signUpErrorMessage = error.localizedDescription
            }
        }
    }

    private static func whenSigningUp(api: GravatarAPI) -> Feedback<State, Event> {
        return Feedback(predicate: { $0.isSigningUp }) { state -> AnyPublisher<Event, Never> in
            return api.getAvatar(state.email)
                .map(Event.signUpSucceeded)
                .replaceError(replace: Event.signUpFailed)
        }
    }
}
