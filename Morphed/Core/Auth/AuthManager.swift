// morphed-ios/Morphed/Core/Auth/AuthManager.swift

import Foundation
import AuthenticationServices
import Combine
import Supabase
import UIKit

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    
    static let shared = AuthManager()
    
    private var authStateTask: Task<Void, Never>?
    private var webAuthSession: ASWebAuthenticationSession?
    private let presentationContextProvider = AuthPresentationContextProvider()
    
    private init() {
        syncFromCurrentUser()
        listenForAuthChanges()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    func checkAuthentication() {
        syncFromCurrentUser()
    }
    
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        _ = try await supabase.auth.signIn(email: email, password: password)
        try await refreshSessionAndValidateProfile()
    }

    func login(identifier: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        if trimmed.contains("@") {
            _ = try await supabase.auth.signIn(email: trimmed, password: password)
        } else {
            _ = try await supabase.auth.signIn(phone: trimmed, password: password)
        }
        
        try await refreshSessionAndValidateProfile()
    }
    
    func signUp(email: String, password: String, name: String) async throws -> Bool {
        try await signUp(identifier: email, password: password, name: name)
    }

    func signUp(identifier: String, password: String, name: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty, !name.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        let metadata: [String: AnyJSON] = ["name": .string(name)]
        if trimmed.contains("@") {
            _ = try await supabase.auth.signUp(email: trimmed, password: password, data: metadata)
        } else {
            _ = try await supabase.auth.signUp(phone: trimmed, password: password, data: metadata)
        }
        let session = try? await supabase.auth.session
        updateFromSession(session)
        if let user = session?.user ?? supabase.auth.currentUser {
            await createOrUpdateProfile(for: user, nameOverride: name)
        }
        return session == nil
    }
    
    func signInWithOAuth(provider: Provider) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = try await supabase.auth.getOAuthSignInURL(
            provider: provider,
            redirectTo: SupabaseConfig.redirectURL
        )
        
        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: SupabaseConfig.redirectScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL else {
                    continuation.resume(throwing: AuthError.oauthFailed)
                    return
                }
                
                continuation.resume(returning: callbackURL)
            }
            
            session.presentationContextProvider = presentationContextProvider
            session.prefersEphemeralWebBrowserSession = true
            webAuthSession = session
            session.start()
        }
        
        webAuthSession = nil
        _ = try await supabase.auth.session(from: callbackURL)
        try await refreshSessionAndValidateProfile()
    }
    
    func logout() async {
        isLoading = true
        defer { isLoading = false }
        
        try? await supabase.auth.signOut()
        updateFromSession(nil)
    }
    
    private func listenForAuthChanges() {
        authStateTask?.cancel()
        authStateTask = Task { [weak self] in
            for await (_, session) in await supabase.auth.authStateChanges {
                await MainActor.run {
                    self?.updateFromSession(session)
                }
            }
        }
    }
    
    private func syncFromCurrentUser() {
        if let user = supabase.auth.currentUser {
            currentUser = AppUser(from: user)
            isAuthenticated = true
        }
    }
    
    private func refreshSession() async {
        let session = try? await supabase.auth.session
        updateFromSession(session)
    }

    private func refreshSessionAndValidateProfile() async throws {
        let session = try? await supabase.auth.session
        updateFromSession(session)
        guard let user = session?.user ?? supabase.auth.currentUser else {
            throw AuthError.invalidCredentials
        }
        let exists = await profileExists(for: user)
        if !exists {
            try? await supabase.auth.signOut()
            updateFromSession(nil)
            throw AuthError.profileMissing
        }
    }
    
    private func updateFromSession(_ session: Session?) {
        if let user = session?.user ?? supabase.auth.currentUser {
            currentUser = AppUser(from: user)
            isAuthenticated = true
        } else {
            currentUser = nil
            isAuthenticated = false
        }
    }

    private func createOrUpdateProfile(for user: Supabase.User, nameOverride: String? = nil) async {
        let nameFromMetadata = user.userMetadata["name"]?.stringValue
        let fallbackName = user.email?.components(separatedBy: "@").first?.capitalized ?? "User"
        let resolvedName = nameOverride?.isEmpty == false ? nameOverride! : (nameFromMetadata ?? fallbackName)
        let payload = ProfilePayload(
            id: user.id.uuidString,
            email: user.email,
            phone: user.phone,
            name: resolvedName
        )
        
        do {
            try await supabase.from("profiles")
                .upsert(payload, onConflict: "id")
                .execute()
        } catch {
            // Non-fatal: auth should still succeed even if profile upsert fails.
        }
    }
    
    private func profileExists(for user: Supabase.User) async -> Bool {
        do {
            let response: PostgrestResponse<ProfileCheck> = try await supabase
                .from("profiles")
                .select("id")
                .eq("id", value: user.id.uuidString)
                .single()
                .execute()
            return !response.value.id.isEmpty
        } catch {
            return false
        }
    }
}

private struct ProfileCheck: Decodable {
    let id: String
}

private struct ProfilePayload: Encodable {
    let id: String
    let email: String?
    let phone: String?
    let name: String
}

struct AppUser: Codable {
    let id: String
    let email: String
    let name: String
    
    init(from user: Supabase.User) {
        self.id = String(describing: user.id)
        self.email = user.email ?? ""
        if let emailName = user.email?.components(separatedBy: "@").first, !emailName.isEmpty {
            self.name = emailName.capitalized
        } else {
            self.name = "User"
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidPhone
    case invalidOTP
    case oauthFailed
    case profileMissing
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidPhone:
            return "Enter a valid phone number"
        case .invalidOTP:
            return "Enter the verification code"
        case .oauthFailed:
            return "OAuth failed. Please try again."
        case .profileMissing:
            return "Account not verified yet. Try again or sign up."
        case .networkError:
            return "Network error. Please try again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let window = scene?.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
