// morphed-ios/Morphed/Features/Auth/SignUpView.swift

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.midnightNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.offWhite)
                            
                            Text("Join Morphed and start transforming your photos")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.offWhite.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.offWhite)
                                
                                TextField("", text: $name, prompt: Text("Enter your name").foregroundColor(.offWhite.opacity(0.5)))
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.offWhite)
                                    .autocapitalization(.words)
                                    .padding()
                                    .background(Color.deepSlate)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .name ? Color.cyberCyan : Color.clear, lineWidth: 2)
                                    )
                                    .focused($focusedField, equals: .name)
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.offWhite)
                                
                                TextField("", text: $email, prompt: Text("Enter your email").foregroundColor(.offWhite.opacity(0.5)))
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.offWhite)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                                    .padding()
                                    .background(Color.deepSlate)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .email ? Color.cyberCyan : Color.clear, lineWidth: 2)
                                    )
                                    .focused($focusedField, equals: .email)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.offWhite)
                                
                                SecureField("", text: $password, prompt: Text("Create a password").foregroundColor(.offWhite.opacity(0.5)))
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.offWhite)
                                    .padding()
                                    .background(Color.deepSlate)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .password ? Color.cyberCyan : Color.clear, lineWidth: 2)
                                    )
                                    .focused($focusedField, equals: .password)
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.offWhite)
                                
                                SecureField("", text: $confirmPassword, prompt: Text("Confirm your password").foregroundColor(.offWhite.opacity(0.5)))
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.offWhite)
                                    .padding()
                                    .background(Color.deepSlate)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .confirmPassword ? Color.cyberCyan : Color.clear, lineWidth: 2)
                                    )
                                    .focused($focusedField, equals: .confirmPassword)
                            }
                            
                            // Sign Up Button
                            Button(action: {
                                Task {
                                    await handleSignUp()
                                }
                            }) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign Up")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                            .foregroundColor(.midnightNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: isValid ? [Color.electricBlue, Color.cyberCyan] : [Color.deepSlate],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            }
                            .disabled(!isValid || authManager.isLoading)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.offWhite)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func handleSignUp() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        do {
            try await authManager.signUp(email: email, password: password, name: name)
            Haptics.notification(type: .success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
    }
}

