// morphed-ios/Morphed/Features/Settings/SettingsView.swift

import SwiftUI
import UIKit
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var router = AppRouter.shared
    @State private var baseURL: String = UserDefaults.standard.string(forKey: "morphed_base_url") ?? "http://localhost:3000"
    @State private var showResetAlert = false
    @State private var showLogoutAlert = false
    @State private var showShareSheet = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    
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
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Account Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            SectionHeader("Account")
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SettingsMenuItem(
                                    icon: "crown.fill",
                                    title: "Premium",
                                    color: .primaryAccent,
                                    showBadge: isPro
                                ) {
                                    Haptics.impact(style: .light)
                                    router.showPremium()
                                }
                                
                                SettingsMenuItem(
                                    icon: "person.2.wave.2.fill",
                                    title: "Invite Friends",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    showShareSheet = true
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        // Support Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            SectionHeader("Support")
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SettingsMenuItem(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    router.openSupportEmail()
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Legal Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            SectionHeader("Legal")
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SettingsMenuItem(
                                    icon: "doc.text.fill",
                                    title: "Terms of Service",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    showTerms = true
                                }
                                
                                SettingsMenuItem(
                                    icon: "lock.shield.fill",
                                    title: "Privacy Policy",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    showPrivacy = true
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // API Configuration (Development)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            SectionHeader("Development")
                            
                            MorphedCard {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    Text("Base URL")
                                        .font(.system(.subheadline, design: .default, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                    
                                    TextField("http://localhost:3000", text: $baseURL)
                                        .textFieldStyle(.plain)
                                        .font(.system(.body, design: .default))
                                        .foregroundColor(.textPrimary)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .keyboardType(.URL)
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(Color.secondaryAccent.opacity(0.5))
                                        .cornerRadius(DesignSystem.CornerRadius.sm)
                                    
                                    Text("For iOS Simulator: use http://localhost:3000\nFor physical device: use your computer's LAN IP (e.g., http://192.168.1.100:3000)")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.textSecondary)
                                        .lineSpacing(4)
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Save Button
                            MorphedButton(
                                "Save",
                                icon: "checkmark.circle.fill",
                                style: .primary
                            ) {
                                UserDefaults.standard.set(baseURL, forKey: "morphed_base_url")
                                Haptics.notification(type: .success)
                                dismiss()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Reset Button
                            Button(action: {
                                showResetAlert = true
                            }) {
                                Text("Reset to Default")
                                    .font(.system(.body, design: .default, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Logout Button
                        MorphedButton(
                            "Log Out",
                            icon: "arrow.right.square.fill",
                            style: .secondary
                        ) {
                            showLogoutAlert = true
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.sm)
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Haptics.impact(style: .light)
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
            .sheet(isPresented: $router.showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: router.shareReferralLink())
            }
            .sheet(isPresented: $showTerms) {
                SafariView(url: router.openTerms())
            }
            .sheet(isPresented: $showPrivacy) {
                SafariView(url: router.openPrivacy())
            }
            .alert("Reset to Default?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset") {
                    baseURL = "http://localhost:3000"
                    UserDefaults.standard.removeObject(forKey: "morphed_base_url")
                    Haptics.notification(type: .success)
                }
            } message: {
                Text("This will reset the base URL to http://localhost:3000")
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    Task {
                        await authManager.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

struct SettingsMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    var showBadge: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if showBadge {
                    PremiumBadge(size: .small)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(Color.divider.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

