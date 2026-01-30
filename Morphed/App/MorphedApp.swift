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
                    // Auth callback only. iOS purchase flow uses StoreKit 2 + backend verify (no Stripe deep link).
                    Task {
                        await authManager.handleAuthCallback(url: url)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
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
                // Refresh entitlements from backend (source of truth) when user logs in.
                if let userId = authManager.currentUser?.id, !userId.isEmpty {
                    Task {
                        await subscriptionManager.refreshEntitlements(userId: userId)
                    }
                    hasSeenOnboardingForCurrentUser = UserDefaults.standard.bool(forKey: "has_seen_onboarding_\(userId)")
                } else {
                    hasSeenOnboardingForCurrentUser = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
                }

                if hasSeenOnboardingForCurrentUser {
                    router.navigateToEditor()
                } else {
                    showOnboarding = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh entitlements when app becomes active (recovery for failed syncs)
            if authManager.isAuthenticated, let userId = authManager.currentUser?.id, !userId.isEmpty {
                Task {
                    await subscriptionManager.refreshEntitlements(userId: userId)
                }
            }
        }
    }
}
