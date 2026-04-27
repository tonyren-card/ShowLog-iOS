import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State private var isSignUp = false
    @State private var email    = ""
    @State private var password = ""
    @State private var loading  = false
    @State private var error    = ""
    @State private var confirmMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Toggle
                Picker("", selection: $isSignUp) {
                    Text("Sign In").tag(false)
                    Text("Sign Up").tag(true)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                if !error.isEmpty {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.system(size: 13))
                }

                if !confirmMessage.isEmpty {
                    Text(confirmMessage)
                        .foregroundStyle(Color.showGreen)
                        .font(.system(size: 13))
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if loading {
                            ProgressView()
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.showGreen)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(loading || email.isEmpty || password.isEmpty)

                Spacer()
            }
            .padding(24)
            .background(Color.background)
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        error = ""; confirmMessage = ""; loading = true
        defer { loading = false }
        do {
            if isSignUp {
                try await state.signUp(email: email, password: password)
                confirmMessage = "Check your email to confirm your account."
            } else {
                try await state.signIn(email: email, password: password)
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
