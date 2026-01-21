// morphed-ios/Morphed/Features/Profile/ProfileView.swift

import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.midnightNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.electricBlue, Color.cyberCyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .cyberCyan.opacity(0.5), radius: 10)
                                
                                Text(initials)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.midnightNavy)
                            }
                            
                            // Name
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.offWhite)
                            
                            // Email
                            Text(authManager.currentUser?.email ?? "")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.offWhite.opacity(0.6))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Menu Items
                        VStack(spacing: 12) {
                            ProfileMenuItem(
                                icon: "gearshape.fill",
                                title: "Settings",
                                color: .electricBlue
                            ) {
                                showSettings = true
                            }
                            
                            ProfileMenuItem(
                                icon: "crown.fill",
                                title: "Premium",
                                color: .cyberCyan,
                                showBadge: true
                            ) {
                                showPaywall = true
                            }
                            
                            ProfileMenuItem(
                                icon: "person.2.wave.2.fill",
                                title: "Invite Friends (Referral)",
                                color: .electricBlue
                            ) {
                                if let link = ReferralManager.referralLink() {
                                    UIPasteboard.general.string = link.absoluteString
                                }
                                Haptics.notification(type: .success)
                            }
                            
                            ProfileMenuItem(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                color: .cyberCyan
                            ) {
                                // Help action
                            }
                            
                            ProfileMenuItem(
                                icon: "doc.text.fill",
                                title: "Terms of Service",
                                color: .offWhite.opacity(0.5)
                            ) {
                                // Terms action
                            }
                            
                            ProfileMenuItem(
                                icon: "lock.shield.fill",
                                title: "Privacy Policy",
                                color: .offWhite.opacity(0.5)
                            ) {
                                // Privacy action
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Logout Button
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.cyberCyan)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.deepSlate)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.cyberCyan.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // App Version
                        Text("Version 1.0.0")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.offWhite.opacity(0.4))
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private var initials: String {
        let name = authManager.currentUser?.name ?? "User"
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    var showBadge: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.offWhite)
            
            Spacer()
            
            if showBadge {
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.midnightNavy)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color.cyberCyan, Color.electricBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.offWhite.opacity(0.3))
        }
        .padding(16)
        .background(Color.deepSlate)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyberCyan.opacity(0.1), lineWidth: 1)
        )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

