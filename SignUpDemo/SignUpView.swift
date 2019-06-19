import SwiftUI

struct SignUpView : View {
    @ObjectBinding var model: SignUpViewModel

    init(model: SignUpViewModel) {
        self.model = model
    }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Credentials").font(.body).padding([.top, .bottom])) {
                        HStack {
                            Text("Email:")
                                .frame(width: 100, alignment: .leading)
                            TextField(
                                $model.state.email,
                                placeholder: Text("email address")
                            )
                            .textContentType(.emailAddress)
                            .clipped()
                        }
                        PasswordField(
                            $model.state.password,
                            label: Text("Password:"),
                            placeholder: Text("********")
                        )
                        PasswordField(
                            $model.state.passwordConfirmation,
                            label: Text("Confirm Password:"),
                            placeholder: Text("********")
                        )
                    }
                    Section(header: Text("Sign Up").font(.body).padding([.top, .bottom])) {
                        VStack {
                            HStack {
                                Spacer()
                                // using Text here instead of Button to avoid bug where a
                                // Button insisde a list cell makes the entire cell the tap
                                // area of the Button and highlights the entire cell
                                // Feedback: FB6133052
                                Text("Sign Up").font(.body)
                                    .tapAction({ self.model.signUp() })
                                    .disabled(model.state.isSignUpButtonEnabled == false)
                                    .foregroundColor(model.state.isSignUpButtonEnabled ? .blue : .gray)
                                Spacer()
                            }.padding()

                            model.state.signUpErrorMessage.map { message in
                                HStack {
                                    Spacer()
                                    Text(message)
                                        .foregroundColor(.red)
                                    Spacer()
                                }.padding()
                            }

                            model.state.avatar.map { avatar in
                                HStack {
                                    Spacer()
                                    Image(uiImage: avatar)
                                        .resizable()
                                        .frame(width: 256, height: 256)
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(Circle())
                                        .shadow(radius: 10)
                                    Spacer()
                                }.padding()
                            }
                        }
                    }
                }//.listStyle(.grouped)
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

            // using Image here instead of Button to avoid bug where a
            // Button insisde a list cell makes the entire cell the tap
            // area of the Button and highlights the entire cell
            // Feedback: FB6133052
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
        SignUpView(model: SignUpViewModel(api: GravatarAPI.mockFailure))
    }
}
#endif
