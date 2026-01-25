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
    
    private var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "has_seen_onboarding")
    }
    
    private var shouldShowOnboarding: Bool {
        // Only show onboarding for new users (not logged in and haven't seen it)
        !authManager.isAuthenticated && !hasSeenOnboarding
    }
    
    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(DesignSystem.Animation.standard, value: authManager.isAuthenticated)
        .animation(DesignSystem.Animation.standard, value: showOnboarding)
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                router.navigateToEditor()
            }
        }
    }
}
