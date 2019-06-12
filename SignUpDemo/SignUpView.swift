import SwiftUI
import Combine

struct SignUpView : View {
    typealias Action = SignUpViewModel.Action

    @EnvironmentObject var model: SignUpViewModel

    var body: some View {
        return NavigationView {
            VStack {
                List {
                    Section(header: Text("Credentials").font(.body).padding([.top, .bottom])) {
                        HStack {
                            Text("Email:")
                                .frame(width: 100, alignment: .leading)
                            TextField(
                                model.binding(
                                    \.email,
                                    action: Action.didChangeEmail
                                ),
                                placeholder: Text("email address")
                            ).clipped()
                        }
                        PasswordField(
                            model.binding(
                                \.password,
                                action: Action.didChangePassword
                            ),
                            label: Text("Password:"),
                            placeholder: Text("********")
                        )
                        PasswordField(
                            model.binding(
                                \.passwordConfirmation,
                                action: Action.didChangePasswordConfirmation
                            ),
                            label: Text("Confirm Password:"),
                            placeholder: Text("********")
                        )
                    }
                    Section(header: Text("Sign Up").font(.body).padding([.top, .bottom])) {
                        VStack {
                            HStack {
                                Spacer()
                                Text("Sign Up").font(.body)
                                    .tapAction({ self.model.sendAction(Action.didTapSignUp) })
                                    .disabled(model.state.isSignUpButtonEnabled == false)
                                    .foregroundColor(model.state.isSignUpButtonEnabled ? .blue : .gray)
                                Spacer()
                            }.padding()

                            if model.state.signUpErrorMessage != nil {
                                HStack {
                                    Spacer()
                                    Text(model.state.signUpErrorMessage ?? "")
                                        .foregroundColor(.red)
                                    Spacer()
                                }.padding()
                            }
                        }
                    }
                }.listStyle(.grouped)
            }.navigationBarTitle(Text("Sign up"))
        }
    }
}

struct PasswordField: View {
    let binding: Binding<String>
    let label: Text
    let placeholder: Text

    // @State is used for state that is entirely local to the view
    @State var isPasswordVisible = false

    init(
        _ binding: Binding<String>,
        label: Text,
        placeholder: Text
    ) {
        self.binding = binding
        self.label = label
        self.placeholder = placeholder
    }

    var body: some View {
        HStack {
            label.frame(width: 100, alignment: .leading)

            if isPasswordVisible {
                TextField(binding, placeholder: placeholder)
                    .textContentType(.password)
                    .clipped()
            } else {
                SecureField(binding, placeholder: placeholder)
                    .textContentType(.password)
                    .clipped()
            }

            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                .foregroundColor(Color.blue)
                .tapAction {
                    self.isPasswordVisible.toggle()
                }
        }.lineLimit(nil)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
#endif
