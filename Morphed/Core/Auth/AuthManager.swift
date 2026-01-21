// morphed-ios/Morphed/Core/Auth/AuthManager.swift

import Foundation
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    static let shared = AuthManager()
    
    private let userDefaults = UserDefaults.standard
    private let authKey = "morphed_user_auth"
    
    private init() {
        checkAuthentication()
    }
    
    func checkAuthentication() {
        if let userData = userDefaults.data(forKey: authKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Master credentials - placeholder for now
        let masterEmail = "morphed123@him.com"
        let masterPassword = "1234567"
        
        // Check for master credentials first
        if email.lowercased() == masterEmail.lowercased() && password == masterPassword {
            let user = User(
                id: "master_user_001",
                email: masterEmail,
                name: "Master User",
                createdAt: Date()
            )
            
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: authKey)
            }
            
            self.currentUser = user
            self.isAuthenticated = true
            return
        }
        
        // Regular authentication - in production, call your backend
        if !email.isEmpty && !password.isEmpty {
            let user = User(
                id: UUID().uuidString,
                email: email,
                name: email.components(separatedBy: "@").first?.capitalized ?? "User",
                createdAt: Date()
            )
            
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: authKey)
            }
            
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Master credentials can also be used for signup
        let masterEmail = "morphed123@him.com"
        let masterPassword = "1234567"
        
        // Check for master credentials first
        if email.lowercased() == masterEmail.lowercased() && password == masterPassword {
            let user = User(
                id: "master_user_001",
                email: masterEmail,
                name: "Master User",
                createdAt: Date()
            )
            
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: authKey)
            }
            
            self.currentUser = user
            self.isAuthenticated = true
            return
        }
        
        // Regular signup - in production, call your backend
        if !email.isEmpty && !password.isEmpty && !name.isEmpty {
            let user = User(
                id: UUID().uuidString,
                email: email,
                name: name,
                createdAt: Date()
            )
            
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: authKey)
            }
            
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    func logout() {
        userDefaults.removeObject(forKey: authKey)
        currentUser = nil
        isAuthenticated = false
    }
}

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please try again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

