import SwiftUI
import Combine

class SignUpViewModel: ObservableObject {

    let gravatarAPI: GravatarAPI

    @Published var state: State {
        didSet {
            dump(state)

            if state.status != oldValue.status {
                switch state.status {
                case .signingUp:
                    SignUpViewModel.signUp(email: state.email, api: gravatarAPI, sender: send(event:))
                case .editing:
                    break
                }
            }
        }
    }

    init(
        api: GravatarAPI = GravatarAPI.live
    ) {
        gravatarAPI = api
        state = State()
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

    enum Action {
        case didChangeEmail(String)
        case didChangePassword(String)
        case didChangePasswordConfirmation(String)
        case didTapSignUp
    }

    enum Event {
        case ui(Action)
        case signUpFailed(SignUpError)
        case signUpSucceeded(UIImage)
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
            get: { self.state[keyPath: keyPath] },
            set: { value in
                if let action = self.action(for: keyPath) {
                    self.send(action: action(value))
                }
            }
        )
    }

    func send(event: Event) {
        state = SignUpViewModel.reduce(state: state, event: event)
    }

    func send(action: Action) {
        send(event: .ui(action))
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

    private static func signUp(email: String, api: GravatarAPI, sender: @escaping (Event) -> Void) {
        api.getAvatar(email) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    sender(.signUpSucceeded(image))
                case let .failure(error):
                    sender(.signUpFailed(error))
                }
            }
        }
    }
}
