// morphed-ios/Morphed/Features/Settings/SettingsView.swift

import SwiftUI
import UIKit
import SafariServices
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var router: AppRouter
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var showDeleteHistoryAlert = false
    @State private var showDeleteHistoryError = false
    @State private var deleteHistoryErrorMessage = ""
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLicenses = false
    @State private var showWhatsNew = false
    @AppStorage("morphed_auto_save_to_photos") private var autoSaveToPhotos = true
    @AppStorage("morphed_default_edit_mode") private var defaultEditModeRaw = EditorViewModel.EditMode.presence.rawValue
    
    private var isPro: Bool {
        subscriptionManager.state.tier != .free
    }

    private var defaultEditMode: EditorViewModel.EditMode {
        EditorViewModel.EditMode(rawValue: defaultEditModeRaw) ?? .presence
    }
    
    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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
                                    icon: "creditcard.fill",
                                    title: "Manage Subscription",
                                    color: .primaryAccent,
                                    showBadge: isPro
                                ) {
                                    Haptics.impact(style: .light)
                                    router.showPremium()
                                }

                                SettingsMenuItem(
                                    icon: "trash.fill",
                                    title: "Delete Account",
                                    color: .red
                                ) {
                                    Haptics.impact(style: .light)
                                    showDeleteAlert = true
                                }
                                
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        // Preferences Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            SectionHeader("Preferences")
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SettingsToggleRow(
                                    icon: "square.and.arrow.down",
                                    title: "Auto Save to Photos",
                                    color: .textSecondary,
                                    isOn: $autoSaveToPhotos
                                )
                                
                                Menu {
                                    ForEach(EditorViewModel.EditMode.allCases, id: \.self) { mode in
                                        Button(mode.displayName) {
                                            Haptics.impact(style: .light)
                                            defaultEditModeRaw = mode.rawValue
                                        }
                                    }
                                } label: {
                                    SettingsValueRow(
                                        icon: "slider.horizontal.3",
                                        title: "Default Edit Mode",
                                        value: defaultEditMode.displayName,
                                        color: .textSecondary
                                    )
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
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
                                    icon: "gearshape.fill",
                                    title: "Permissions",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    openAppSettings()
                                }
                                
                                SettingsMenuItem(
                                    icon: "tray.and.arrow.down.fill",
                                    title: "Data Export",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    openSupportEmail(subject: "Data Export Request")
                                }

                                SettingsMenuItem(
                                    icon: "trash",
                                    title: "Delete History",
                                    color: .red
                                ) {
                                    Haptics.impact(style: .light)
                                    showDeleteHistoryAlert = true
                                }

                                SettingsMenuItem(
                                    icon: "face.smiling.fill",
                                    title: "Face & Body Data Usage",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    showPrivacy = true
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
                                
                                SettingsMenuItem(
                                    icon: "doc.plaintext.fill",
                                    title: "Licenses & Attributions",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    showLicenses = true
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }

                        // About Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            SectionHeader("About")
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SettingsInfoRow(
                                    icon: "info.circle.fill",
                                    title: "App Version",
                                    value: appVersionText,
                                    color: .textSecondary
                                )
                                
                                SettingsMenuItem(
                                    icon: "sparkles",
                                    title: "What's New",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    showWhatsNew = true
                                }
                                
                                SettingsMenuItem(
                                    icon: "star.fill",
                                    title: "Rate Morphed",
                                    color: .textSecondary
                                ) {
                                    Haptics.impact(style: .light)
                                    SKStoreReviewController.requestReview()
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
            .sheet(isPresented: $showTerms) {
                SafariView(url: router.openTerms())
            }
            .sheet(isPresented: $showPrivacy) {
                SafariView(url: router.openPrivacy())
            }
            .sheet(isPresented: $showLicenses) {
                InfoSheetView(
                    title: "Licenses & Attributions",
                    message: "Open-source licenses and attributions will appear here."
                )
            }
            .sheet(isPresented: $showWhatsNew) {
                InfoSheetView(
                    title: "What's New",
                    message: "You're on version \(appVersionText)."
                )
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
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("This permanently deletes your account and all associated data. There is no account recovery.")
            }
            .alert("Delete History", isPresented: $showDeleteHistoryAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete History", role: .destructive) {
                    Task {
                        await deleteHistory()
                    }
                }
            } message: {
                Text("This deletes all saved edits from this device and removes their images from your account. This action cannot be undone.")
            }
            .alert("Delete Failed", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage.isEmpty ? "Please try again." : deleteErrorMessage)
            }
            .alert("Delete History Failed", isPresented: $showDeleteHistoryError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteHistoryErrorMessage.isEmpty ? "Please try again." : deleteHistoryErrorMessage)
            }
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openSupportEmail(subject: String, body: String? = nil) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        var urlString = "mailto:support@morphed.app?subject=\(encodedSubject)"
        if let encodedBody {
            urlString += "&body=\(encodedBody)"
        }
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    @MainActor
    private func deleteAccount() async {
        deleteErrorMessage = ""
        do {
            try await authManager.deleteAccount()
            Haptics.notification(type: .success)
            dismiss()
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }

    @MainActor
    private func deleteHistory() async {
        deleteHistoryErrorMessage = ""
        do {
            try await authManager.deleteHistory()
            Haptics.notification(type: .success)
        } catch {
            deleteHistoryErrorMessage = error.localizedDescription
            showDeleteHistoryError = true
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

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(.body, design: .default, weight: .medium))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .stroke(Color.divider.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SettingsValueRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(.body, design: .default, weight: .medium))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .foregroundColor(.textSecondary)
            
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
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(.body, design: .default, weight: .medium))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: .default, weight: .semibold))
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
}

struct InfoSheetView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let message: String
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    Text(message)
                        .font(.system(.body, design: .default, weight: .regular))
                        .foregroundColor(.textPrimary)
                        .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle(title)
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
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
