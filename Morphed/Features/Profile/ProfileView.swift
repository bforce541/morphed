// morphed-ios/Morphed/Features/Profile/ProfileView.swift

import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var router: AppRouter
    @State private var isEditingName = false
    @State private var nameDraft = ""
    @State private var isSavingName = false
    @State private var nameError: String?
    @State private var showAvatarPicker = false
    @State private var avatarDraft: UIImage?
    @State private var isUploadingAvatar = false
    @State private var avatarError: String?
    @State private var avatarCacheBust = UUID().uuidString
    @State private var showNameConfirm = false
    @State private var showAvatarConfirm = false
    @State private var pendingName: String = ""
    @State private var pendingAvatar: UIImage?
    
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
                                .overlay(
                                    Group {
                                        if let avatarURL = authManager.currentUser?.avatarURL,
                                           let url = URL(string: avatarURLForDisplay(avatarURL)) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                case .failure:
                                                    Text(initials)
                                                        .font(.system(size: 48, weight: .bold, design: .default))
                                                        .foregroundColor(.midnightNavy)
                                                default:
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .midnightNavy))
                                                }
                                            }
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                        } else {
                                            Text(initials)
                                                .font(.system(size: 48, weight: .bold, design: .default))
                                                .foregroundColor(.midnightNavy)
                                        }
                                    }
                                )
                                
                                if isUploadingAvatar {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .midnightNavy))
                                }
                                
                                Button(action: {
                                    Haptics.impact(style: .light)
                                    showAvatarPicker = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.midnightNavy)
                                        .padding(8)
                                        .background(Color.primaryAccent)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primaryAccent.opacity(0.6), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .offset(x: 44, y: 44)
                            }
                            .padding(.top, DesignSystem.Spacing.lg)
                            
                            // Name
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                if isEditingName {
                                    TextField("Name", text: $nameDraft)
                                        .font(.system(.title2, design: .default, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                        .padding(.vertical, DesignSystem.Spacing.sm)
                                        .background(Color.cardBackground)
                                        .cornerRadius(DesignSystem.CornerRadius.sm)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                                .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                                        )
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                        .frame(maxWidth: 320)
                                    
                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                        Button("Cancel") {
                                            Haptics.impact(style: .light)
                                            nameDraft = authManager.currentUser?.name ?? "User"
                                            nameError = nil
                                            isEditingName = false
                                        }
                                        .font(.system(.subheadline, design: .default, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                        
                                        Button(action: {
                                            Haptics.impact(style: .medium)
                                            let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                            pendingName = trimmed
                                            showNameConfirm = true
                                        }) {
                                            if isSavingName {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .midnightNavy))
                                            } else {
                                                Text("Save")
                                                    .font(.system(.subheadline, design: .default, weight: .semibold))
                                                    .foregroundColor(.midnightNavy)
                                            }
                                        }
                                        .disabled(isSavingName)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.primaryAccent)
                                        .cornerRadius(8)
                                    }
                                    
                                    if let nameError {
                                        Text(nameError)
                                            .font(.system(.caption, design: .default))
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    Text(authManager.currentUser?.name ?? "User")
                                        .font(.system(.largeTitle, design: .default, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                    
                                    Button(action: {
                                        Haptics.impact(style: .light)
                                        nameDraft = authManager.currentUser?.name ?? "User"
                                        nameError = nil
                                        isEditingName = true
                                    }) {
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 12, weight: .semibold))
                                            Text("Edit name")
                                                .font(.system(.subheadline, design: .default, weight: .semibold))
                                        }
                                        .foregroundColor(.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Email
                            Text(authManager.currentUser?.email ?? "")
                                .font(.system(.subheadline, design: .default))
                                .foregroundColor(.textSecondary)
                            
                            if let avatarError {
                                Text(avatarError)
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(.red)
                            }
                            
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
                                    Text("HD & Physique, Face, Style locked")
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
            .sheet(isPresented: $showAvatarPicker) {
                ImagePicker(selectedImage: $avatarDraft)
            }
            .alert("Change name?", isPresented: $showNameConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingName = ""
                }
                Button("OK") {
                    Task {
                        await saveName()
                    }
                }
            } message: {
                Text("This will update your profile name.")
            }
            .alert("Change profile photo?", isPresented: $showAvatarConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingAvatar = nil
                    avatarDraft = nil
                }
                Button("OK") {
                    if let image = pendingAvatar {
                        Task {
                            await uploadAvatar(image)
                        }
                    }
                }
            } message: {
                Text("This will replace your current photo.")
            }
        }
        .onAppear {
            if nameDraft.isEmpty {
                nameDraft = authManager.currentUser?.name ?? "User"
            }
        }
        .onChange(of: avatarDraft) { newValue in
            guard let image = newValue else { return }
            pendingAvatar = image
            showAvatarConfirm = true
        }
        .onChange(of: authManager.currentUser?.avatarURL) { _ in
            avatarCacheBust = UUID().uuidString
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
    
    @MainActor
    private func saveName() async {
        let trimmed = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            nameError = "Please enter a name."
            return
        }
        
        isSavingName = true
        nameError = nil
        
        do {
            try await authManager.updateProfileName(trimmed)
            isEditingName = false
            pendingName = ""
        } catch {
            nameError = error.localizedDescription
        }
        
        isSavingName = false
    }
    
    @MainActor
    private func uploadAvatar(_ image: UIImage) async {
        isUploadingAvatar = true
        avatarError = nil
        
        do {
            try await authManager.updateProfileAvatar(image)
            avatarCacheBust = UUID().uuidString
            avatarDraft = nil
            pendingAvatar = nil
        } catch {
            avatarError = error.localizedDescription
        }
        
        isUploadingAvatar = false
    }
    
    private func avatarURLForDisplay(_ url: String) -> String {
        if url.contains("?") {
            return "\(url)&v=\(avatarCacheBust)"
        }
        return "\(url)?v=\(avatarCacheBust)"
    }
}
