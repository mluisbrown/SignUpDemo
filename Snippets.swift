//---------------------------------------------------------------------------------------------
// Stage 1 -> Stage 2

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

//---------------------------------------------------------------------------------------------
// Stage 2 -> Stage 3 (end)

private let input = PassthroughSubject<Event, Never>()
private var cancelable: Cancellable? = nil

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
        scheduler: DispatchQueue.main,
        reduce: SignUpViewModel.reduce
    ).sink { [weak self] state in
        guard let self = self else { return }
        dump(state)
        self.state = state
        self.didChange.send(())
    }
}

deinit {
    didChange.send(completion: .finished)
    input.send(completion: .finished)
    cancelable?.cancel()
}

private static func whenSigningUp(api: GravatarAPI) -> Feedback<State, Event> {
    return Feedback(predicate: { $0.isSigningUp }) { state -> AnyPublisher<Event, Never> in
        return api.getAvatar(state.email)
            .map(Event.signUpSucceeded)
            .replaceError(replace: Event.signUpFailed)
    }
}

struct GravatarAPI {
    private static func MD5(string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }

    let getAvatar: (String) -> AnyPublisher<UIImage, SignUpError>
}

extension GravatarAPI {
    static let live: GravatarAPI = GravatarAPI { email -> AnyPublisher<UIImage, SignUpError> in
        let emailHash = MD5(string: email.lowercased())
        let url = URL(string: "https://www.gravatar.com/avatar/\(emailHash)?s=256&d=404")!

        let request = URLRequest(url: url)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> UIImage in
                let (data, response) = result
                guard let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode,
                    let image = UIImage(data: data) else { throw SignUpError.unknown }

                return image
            }
            .mapError { error -> SignUpError in
                switch error.self {
                case is URLError:
                    return .network(error)
                default:
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }

    static let mockFailure: GravatarAPI = GravatarAPI { email -> AnyPublisher<UIImage, SignUpError> in
        return Publishers.Once(Result<UIImage, SignUpError>.failure(.unknown))
            .eraseToAnyPublisher()
    }

    static let mockSuccess: GravatarAPI = GravatarAPI { email -> AnyPublisher<UIImage, SignUpError> in
        return Publishers.Once(
            Result<UIImage, SignUpError>.success(
                UIImage(
                    systemName: "person.circle",
                    withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 100)
                )!
            )
        )
        .eraseToAnyPublisher()
    }
}