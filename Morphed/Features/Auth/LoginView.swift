// morphed-ios/Morphed/Features/Auth/LoginView.swift

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            Color.midnightNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo and Title
                    VStack(spacing: 16) {
                        if UIImage(named: "AppLogo") != nil {
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .cornerRadius(24)
                                .shadow(color: .cyberCyan.opacity(0.5), radius: 20)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(.cyberCyan)
                                .frame(width: 120, height: 120)
                        }
                        
                        Text("Morphed")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.offWhite)
                        
                        Text("Transform your photos with AI")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.offWhite.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                    
                    // Login Form
                    VStack(spacing: 20) {
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
                            
                            SecureField("", text: $password, prompt: Text("Enter your password").foregroundColor(.offWhite.opacity(0.5)))
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
                        
                        // Login Button
                        Button(action: {
                            Task {
                                await handleLogin()
                            }
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Login")
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
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.offWhite.opacity(0.6))
                            
                            Button(action: {
                                showSignUp = true
                            }) {
                                Text("Sign Up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.cyberCyan)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func handleLogin() async {
        do {
            try await authManager.login(email: email, password: password)
            Haptics.notification(type: .success)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
    }
}

