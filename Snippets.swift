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
        getValue: { self.state[keyPath: keyPath] },
        setValue: { value in
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

