// morphed-ios/Morphed/Features/Auth/SignUpView.swift

import SwiftUI
import Supabase

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var name = ""
    @State private var identifier = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showInfo = false
    @State private var infoMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, identifier, password, confirmPassword
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
                                
                                TextField("", text: $identifier, prompt: Text("Enter your email").foregroundColor(.offWhite.opacity(0.5)))
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
                                            .stroke(focusedField == .identifier ? Color.cyberCyan : Color.clear, lineWidth: 2)
                                    )
                                    .focused($focusedField, equals: .identifier)
                            }
                            
                            // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.offWhite)
                            
                            HStack(spacing: 8) {
                                Group {
                                    if showPassword {
                                        TextField("", text: $password, prompt: Text("Create a password").foregroundColor(.offWhite.opacity(0.5)))
                                    } else {
                                        SecureField("", text: $password, prompt: Text("Create a password").foregroundColor(.offWhite.opacity(0.5)))
                                    }
                                }
                                .textFieldStyle(.plain)
                                .foregroundColor(.offWhite)
                                .focused($focusedField, equals: .password)
                                
                                Button(action: {
                                    Haptics.impact(style: .light)
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.offWhite.opacity(0.7))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                            }
                            .padding()
                            .background(Color.deepSlate)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .password ? Color.cyberCyan : Color.clear, lineWidth: 2)
                            )
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.offWhite)
                            
                            HStack(spacing: 8) {
                                Group {
                                    if showConfirmPassword {
                                        TextField("", text: $confirmPassword, prompt: Text("Confirm your password").foregroundColor(.offWhite.opacity(0.5)))
                                    } else {
                                        SecureField("", text: $confirmPassword, prompt: Text("Confirm your password").foregroundColor(.offWhite.opacity(0.5)))
                                    }
                                }
                                .textFieldStyle(.plain)
                                .foregroundColor(.offWhite)
                                .focused($focusedField, equals: .confirmPassword)
                                
                                Button(action: {
                                    Haptics.impact(style: .light)
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.offWhite.opacity(0.7))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel(showConfirmPassword ? "Hide password" : "Show password")
                            }
                            .padding()
                            .background(Color.deepSlate)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .confirmPassword ? Color.cyberCyan : Color.clear, lineWidth: 2)
                            )
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
                            
                            // Divider
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color.offWhite.opacity(0.2))
                                    .frame(height: 1)
                                Text("OR")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.offWhite.opacity(0.5))
                                Rectangle()
                                    .fill(Color.offWhite.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // OAuth
                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await handleOAuth(.google)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "globe")
                                        Text("Continue with Google")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.offWhite)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.deepSlate)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.offWhite.opacity(0.15), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                                .disabled(authManager.isLoading)
                                
                                Button(action: {
                                    Task {
                                        await handleOAuth(.apple)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "applelogo")
                                        Text("Continue with Apple")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.offWhite)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.deepSlate)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.offWhite.opacity(0.15), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                                .disabled(authManager.isLoading)
                            }
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
        .alert("Notice", isPresented: $showInfo) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(infoMessage)
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
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
            let needsConfirmation = try await authManager.signUp(identifier: identifier, password: password, name: name)
            Haptics.notification(type: .success)
            if needsConfirmation {
                infoMessage = "Check your email to confirm your account, then log in."
                showInfo = true
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
    }
    
    private func handleOAuth(_ provider: Provider) async {
        do {
            try await authManager.signInWithOAuth(provider: provider)
            Haptics.notification(type: .success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
    }
}
