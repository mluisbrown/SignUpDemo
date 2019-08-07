import SwiftUI
import Combine
import CombineFeedback

class ViewModel<State, Action, Event>: ObservableObject {
    private let input = Feedback<State, Change>.input
    private var cancelable: Cancellable? = nil

    @Published var state: State

    init<S: Scheduler>(
        initial: State,
        feedbacks: [Feedback<State, Event>],
        scheduler: S,
        reducer: @escaping (State, Change) -> State
    ) {
        state = initial
        cancelable = Publishers.system(
            initial: initial,
            feedbacks: feedbacks.map { $0.mapEvent(Change.system) } + [input.feedback],
            scheduler: scheduler,
            reduce: reducer
        ).sink { [weak self] state in
            guard let self = self else { return }
            self.state = state
        }
    }

    deinit {
        cancelable?.cancel()
    }

    enum Change {
        case ui(Action)
        case system(Event)
    }

    func send(action: Action) {
        input.observer(.ui(action))
    }

    func action<T>(
        for keyPath: KeyPath<State, T>
    ) -> Optional<(T) -> Action> {
        return nil
    }

    func binding<T>(
        _ keyPath: KeyPath<State, T>
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
}

extension Feedback {
    func mapEvent<U>(_ f: @escaping (Event) -> U) -> Feedback<State, U> {
        return Feedback<State, U>(events: { state -> AnyPublisher<U, Never> in
            self.events(state).map(f).eraseToAnyPublisher()
        })
    }

    static var input: (feedback: Feedback, observer: (Event) -> Void) {
        let subject = PassthroughSubject<Event, Never>()
        let feedback = Feedback(events: { _ in
            return subject
        })
        return (feedback, subject.send)
    }
}


class SignUpViewModel: ViewModel<SignUpViewModel.State, SignUpViewModel.Action, SignUpViewModel.Event> {
    init(
        api: GravatarAPI = GravatarAPI.live
    ) {
        super.init(
            initial: State(),
            feedbacks: [SignUpViewModel.whenSigningUp(api: api)],
            scheduler: DispatchQueue.main,
            reducer: SignUpViewModel.reduce
        )
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
        case signUpFailed(SignUpError)
        case signUpSucceeded(UIImage)
    }

    enum Action {
        case didChangeEmail(String)
        case didChangePassword(String)
        case didChangePasswordConfirmation(String)
        case didTapSignUp
    }

    override func action<T>(
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


    private static func reduce(state: State, event: Change) -> State {
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
        case let .system(event):
            switch event {
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
    }

    private static func whenSigningUp(api: GravatarAPI) -> Feedback<State, Event> {
        return Feedback(predicate: { $0.isSigningUp }) { state -> AnyPublisher<Event, Never> in
            return api.getAvatar(state.email)
                .map(Event.signUpSucceeded)
                .replaceError(replace: Event.signUpFailed)
        }
    }
}
