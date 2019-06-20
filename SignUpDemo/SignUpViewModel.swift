import SwiftUI
import Combine

class SignUpViewModel: BindableObject {

    let didChange = PassthroughSubject<Void, Never>()
    let gravatarAPI: GravatarAPI

    private(set) var state: State {
        didSet {
            dump(state)
            didChange.send(())
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

    func signUp() {
        state.status = .signingUp

        gravatarAPI.getAvatar(state.email) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    self.state.avatar = image
                    self.state.signUpErrorMessage = nil
                case let .failure(error):
                    self.state.avatar = nil
                    self.state.signUpErrorMessage = error.localizedDescription
                }

                self.state.status = .editing
            }
        }
    }
}
