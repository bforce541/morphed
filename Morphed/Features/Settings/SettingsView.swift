// morphed-ios/Morphed/Features/Settings/SettingsView.swift

import SwiftUI
import UIKit
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var router = AppRouter.shared
    @State private var showLogoutAlert = false
    @State private var showShareSheet = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showChangePassword = false
    
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
                        
                        // Privacy & Security Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            SectionHeader("Privacy & Security")
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SettingsMenuItem(
                                    icon: "lock.circle.fill",
                                    title: "Change Password",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    showChangePassword = true
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
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
                    .environmentObject(authManager)
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

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showOldPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    MorphedCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            passwordField(
                                title: "Current Password",
                                placeholder: "Enter current password",
                                text: $oldPassword,
                                isVisible: $showOldPassword
                            )
                            
                            passwordField(
                                title: "New Password",
                                placeholder: "Enter new password",
                                text: $newPassword,
                                isVisible: $showNewPassword
                            )
                            .padding(.top, DesignSystem.Spacing.xs)
                            
                            passwordField(
                                title: "Confirm Password",
                                placeholder: "Re-enter new password",
                                text: $confirmPassword,
                                isVisible: $showConfirmPassword
                            )
                            .padding(.top, DesignSystem.Spacing.xs)
                            
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(.red)
                                    .padding(.top, DesignSystem.Spacing.xs)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    MorphedButton(
                        isSaving ? "Updating..." : "Update Password",
                        icon: isSaving ? nil : "checkmark.circle.fill",
                        style: .primary
                    ) {
                        Task {
                            await updatePassword()
                        }
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    Spacer()
                }
                .padding(.top, DesignSystem.Spacing.lg)
            }
            .navigationTitle("Change Password")
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
        }
    }
    
    @MainActor
    private func updatePassword() async {
        errorMessage = nil
        
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOld = oldPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedOld.isEmpty else {
            errorMessage = "Please enter your current password."
            return
        }
        guard !trimmedNew.isEmpty else {
            errorMessage = "Please enter a new password."
            return
        }
        guard trimmedNew == trimmedConfirm else {
            errorMessage = "Passwords do not match."
            return
        }
        
        isSaving = true
        do {
            try await authManager.updatePassword(oldPassword: trimmedOld, newPassword: trimmedNew)
            Haptics.notification(type: .success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
    
    @ViewBuilder
    private func passwordField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        Text(title)
            .font(.system(.subheadline, design: .default, weight: .medium))
            .foregroundColor(.textSecondary)
        
        HStack(spacing: DesignSystem.Spacing.xs) {
            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(.body, design: .default))
            .foregroundColor(.textPrimary)
            
            Button(action: {
                Haptics.impact(style: .light)
                isVisible.wrappedValue.toggle()
            }) {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isVisible.wrappedValue ? "Hide password" : "Show password")
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.secondaryAccent.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.sm)
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
