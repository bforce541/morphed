// morphed-ios/Morphed/Features/Profile/ProfileView.swift

import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var router = AppRouter.shared
    
    private var isPro: Bool {
        subscriptionManager.state.tier != .free
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Profile Header - Identity Only
                        VStack(spacing: DesignSystem.Spacing.md) {
                            // Avatar with glow
                            ZStack {
                                // Glow ring
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.primaryAccent.opacity(0.3), Color.primaryAccent.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                    .blur(radius: 8)
                                
                                // Avatar circle
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.primaryAccent, Color.primaryAccent.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primaryAccent.opacity(0.5), lineWidth: 2)
                                    )
                                
                                // Initials
                                Text(initials)
                                    .font(.system(size: 48, weight: .bold, design: .default))
                                    .foregroundColor(.midnightNavy)
                            }
                            .padding(.top, DesignSystem.Spacing.lg)
                            
                            // Name
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.system(.largeTitle, design: .default, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            // Email
                            Text(authManager.currentUser?.email ?? "")
                                .font(.system(.subheadline, design: .default))
                                .foregroundColor(.textSecondary)
                            
                            // Account Tier
                            Button(action: {
                                if !isPro {
                                    Haptics.impact(style: .light)
                                    router.showPremium()
                                }
                            }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Text("Account Tier")
                                        .font(.system(.subheadline, design: .default))
                                        .foregroundColor(.textSecondary)
                                    
                                    if isPro {
                                        PremiumBadge(size: .medium)
                                    } else {
                                        Text("Free")
                                            .font(.system(.subheadline, design: .default, weight: .medium))
                                            .foregroundColor(.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.cardBackground)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, DesignSystem.Spacing.xs)
                            
                            // Locked features reminder for free users
                            if !isPro {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                    Text("HD & MAX mode locked")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.top, DesignSystem.Spacing.xs)
                            }
                            
                            // Upgrade button for free users
                            if !isPro {
                                MorphedButton(
                                    "Upgrade to Pro",
                                    icon: "crown.fill",
                                    style: .primary
                                ) {
                                    Haptics.impact(style: .medium)
                                    router.showPremium()
                                }
                                .padding(.horizontal, DesignSystem.Spacing.xl)
                                .padding(.top, DesignSystem.Spacing.md)
                            }
                        }
                        .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(.largeTitle, design: .default, weight: .semibold))
                        .foregroundColor(.titleColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Haptics.impact(style: .light)
                        router.presentSettings()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $router.showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $router.showSettings) {
                SettingsView()
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
