// morphed-ios/Morphed/App/MorphedApp.swift

import SwiftUI

@main
struct MorphedApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "has_seen_onboarding")
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
        .animation(.easeInOut, value: showOnboarding)
    }
}
