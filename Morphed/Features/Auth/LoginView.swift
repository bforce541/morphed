// morphed-ios/Morphed/Features/Auth/LoginView.swift

import SwiftUI
import Supabase

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var identifier = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case identifier, password
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
                        
                        Text("Look like the upgraded version of you")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.offWhite.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email or Phone Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email or Phone")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.offWhite)
                            
                            TextField("", text: $identifier, prompt: Text("Enter your email or phone").foregroundColor(.offWhite.opacity(0.5)))
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    focusedField = .identifier
                                }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.offWhite)
                            
                            HStack(spacing: 8) {
                                Group {
                                    if showPassword {
                                        TextField("", text: $password, prompt: Text("Enter your password").foregroundColor(.offWhite.opacity(0.5)))
                                    } else {
                                        SecureField("", text: $password, prompt: Text("Enter your password").foregroundColor(.offWhite.opacity(0.5)))
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedField = .password
                            }
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
                                    Text("Continue")
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
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }
    
    private func handleLogin() async {
        do {
            try await authManager.login(identifier: identifier, password: password)
            Haptics.notification(type: .success)
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
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
    }
}
