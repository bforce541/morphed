// morphed-ios/Morphed/Features/Main/MainTabView.swift

import SwiftUI

struct MainTabView: View {
    @StateObject private var router = AppRouter.shared
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            EditorView()
                .tabItem {
                    Label("Editor", systemImage: "sparkles")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "photo.on.rectangle.angled")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .accentColor(.primaryAccent)
        .environmentObject(router)
        .sheet(isPresented: $router.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallView()
        }
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.06, green: 0.11, blue: 0.18, alpha: 1.0) // Dark slate background
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.10, green: 0.20, blue: 0.29, alpha: 1.0) // Muted slate
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.10, green: 0.20, blue: 0.29, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.31, green: 0.82, blue: 1.0, alpha: 1.0) // Cyan
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.31, green: 0.82, blue: 1.0, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}
