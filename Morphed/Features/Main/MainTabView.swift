// morphed-ios/Morphed/Features/Main/MainTabView.swift

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EditorView()
                .tabItem {
                    Label("Editor", systemImage: "sparkles")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "photo.on.rectangle")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .accentColor(.cyberCyan)
    }
}

