// morphed-ios/Morphed/App/MorphedApp.swift

import SwiftUI

@main
struct MorphedApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var router = AppRouter.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
                .environmentObject(router)
                .onOpenURL { url in
                    StripePaymentHandler.shared.handleDeepLink(url: url)
                    Task {
                        await authManager.handleAuthCallback(url: url)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var router: AppRouter
    @State private var showOnboarding = false
    @State private var hasSeenOnboardingForCurrentUser = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if showOnboarding {
                    OnboardingView(isPresented: $showOnboarding)
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .animation(DesignSystem.Animation.standard, value: authManager.isAuthenticated)
        .animation(DesignSystem.Animation.standard, value: showOnboarding)
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // Refresh onboarding state for the current user whenever we log in.
                if let userId = authManager.currentUser?.id, !userId.isEmpty {
                    hasSeenOnboardingForCurrentUser = UserDefaults.standard.bool(forKey: "has_seen_onboarding_\(userId)")
                } else {
                    hasSeenOnboardingForCurrentUser = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
                }
                
                if hasSeenOnboardingForCurrentUser {
                    // Existing user: go straight into main app.
                    router.navigateToEditor()
                } else {
                    // First login for this account: present onboarding.
                    showOnboarding = true
                }
            }
        }
    }
}
