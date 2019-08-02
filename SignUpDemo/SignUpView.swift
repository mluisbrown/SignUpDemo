import SwiftUI

struct SignUpView: View {

    @ObservedObject private var model: SignUpViewModel

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
                                "email address",
                                text: model.binding(\.email)
                            )
                            .textContentType(.emailAddress)
                            .clipped()
                        }
                        PasswordField(
                            model.binding(\.password),
                            label: Text("Password:"),
                            placeholder: "********"
                        )
                        PasswordField(
                            model.binding(\.passwordConfirmation),
                            label: Text("Confirm Password:"),
                            placeholder: "********"
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
                                    .onTapGesture { self.model.send(action: .didTapSignUp) }
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
                                }
                                .padding()
                                .lineLimit(nil)
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
                }
            }.navigationBarTitle(Text("Sign up"))
        }
    }
}

struct PasswordField: View {
    let binding: Binding<String>
    let label: Text
    let placeholder: String

    // @State is used for state that is entirely local to the view
    @State var isPasswordVisible = false

    init(
        _ binding: Binding<String>,
        label: Text,
        placeholder: String
    ) {
        self.binding = binding
        self.label = label
        self.placeholder = placeholder
    }

    var body: some View {
        HStack {
            label.frame(width: 100, alignment: .leading)

            if isPasswordVisible {
                TextField(placeholder, text: binding)
                    .textContentType(.password)
                    .clipped()
            } else {
                SecureField(placeholder, text: binding)
                    .textContentType(.password)
                    .clipped()
            }

//            Button(action: { self.isPasswordVisible.toggle() }) {
//                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//            }

            // using Image here instead of Button to avoid bug where a
            // Button insisde a list cell makes the entire cell the tap
            // area of the Button and highlights the entire cell
            // Feedback: FB6133052
            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                .foregroundColor(Color.blue)
                .onTapGesture {
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
