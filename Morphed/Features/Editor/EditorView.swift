// morphed-ios/Morphed/Features/Editor/EditorView.swift

import SwiftUI
import PhotosUI

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @StateObject private var router = AppRouter.shared
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    private var isFree: Bool {
        subscriptionManager.state.tier == .free
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Top bar
                        HStack {
                            Text("Editor")
                                .font(.system(.largeTitle, design: .default, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if viewModel.selectedMode != nil {
                                ModePill(mode: viewModel.selectedMode!)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            Button(action: {
                                Haptics.impact(style: .light)
                                router.presentSettings()
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.sm)
                        
                        // Original Image Card
                        ImageCard(
                            title: "Original",
                            image: viewModel.originalImage,
                            isLoading: false,
                            onSelect: {
                                Haptics.impact(style: .medium)
                                viewModel.showImagePicker = true
                            }
                        )
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Mode Selector
                        if viewModel.originalImage != nil {
                            ModeSelector(
                                selectedMode: $viewModel.selectedMode,
                                onRequireUpgrade: {
                                    Haptics.notification(type: .warning)
                                    router.showPremium()
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Generate Button
                        if viewModel.originalImage != nil {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                MorphedButton(
                                    viewModel.isLoading ? "Enhancing..." : "Generate Upgrade",
                                    icon: viewModel.isLoading ? nil : "sparkles",
                                    style: .primary
                                ) {
                                    Haptics.impact(style: .medium)
                                    Task {
                                        await viewModel.startGenerationStub()
                                    }
                                }
                                .disabled(viewModel.isLoading || viewModel.selectedMode == nil)
                                
                                // Crown icon for free users
                                if isFree && !viewModel.isLoading {
                                    Button(action: {
                                        Haptics.impact(style: .light)
                                        router.showPremium()
                                    }) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.primaryAccent)
                                            .frame(width: 56, height: 56)
                                            .background(Color.cardBackground)
                                            .cornerRadius(DesignSystem.CornerRadius.md)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                                    .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Morphed Image Card
                        if viewModel.editedImage != nil {
                            ImageCard(
                                title: "Morphed",
                                image: viewModel.editedImage,
                                isLoading: false,
                                onSelect: nil
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                            // Save / Export Buttons
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                MorphedButton(
                                    "Save Preview",
                                    icon: "square.and.arrow.down",
                                    style: .primary
                                ) {
                                    Haptics.impact(style: .medium)
                                    Task {
                                        await viewModel.saveToPhotos()
                                    }
                                }
                                
                                MorphedButton(
                                    "Download HD (No Watermark)",
                                    icon: "arrow.down.circle.fill",
                                    style: .secondary
                                ) {
                                    if FeatureGates.canExportHD(subscriptionManager) {
                                        UsageTracker.recordHDExport()
                                        Task {
                                            await viewModel.saveToPhotos()
                                        }
                                    } else {
                                        Haptics.notification(type: .warning)
                                        router.showPremium()
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    Color.backgroundBottom.opacity(0.9)
                        .ignoresSafeArea()
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryAccent))
                            .scaleEffect(1.5)
                        
                        Text("Enhancing...")
                            .font(.system(.body, design: .default, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(DesignSystem.Spacing.xl)
                    .background(Color.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(selectedImage: $viewModel.originalImage)
            }
            .sheet(isPresented: $router.showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $router.showPaywall) {
                PaywallView()
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.hasGeneratedPreview && viewModel.editedImage != nil },
                set: { if !$0 { viewModel.hasGeneratedPreview = false } }
            )) {
                if let previewImage = viewModel.editedImage,
                   let mode = viewModel.selectedMode {
                    PostGenerationPreviewView(
                        previewImage: previewImage,
                        originalImage: viewModel.originalImage,
                        mode: mode
                    )
                    .environmentObject(router)
                }
            }
            .toast(message: viewModel.toastMessage, isPresented: $viewModel.showToast)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .alert("Success", isPresented: $viewModel.showSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Image saved to Photos")
            }
            .onChange(of: subscriptionManager.shouldPresentPaywall) { newValue in
                if newValue {
                    router.showPaywall = true
                    subscriptionManager.consumePaywallTrigger()
                }
            }
            .onChange(of: subscriptionManager.state.tier) { _ in
                // When user upgrades, remove watermark from preview
                if subscriptionManager.state.tier != .free && viewModel.editedImage != nil {
                    viewModel.removeWatermark()
                }
            }
        }
    }
}

struct ModePill: View {
    let mode: EditorViewModel.EditMode
    
    var body: some View {
        Text(mode.displayName)
            .font(.system(size: 12, weight: .semibold, design: .default))
            .foregroundColor(.midnightNavy)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.primaryAccent)
            .cornerRadius(12)
    }
}

struct ModeSelector: View {
    @Binding var selectedMode: EditorViewModel.EditMode?
    var onRequireUpgrade: (() -> Void)?
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(EditorViewModel.EditMode.allCases, id: \.self) { mode in
                Button(action: {
                    if mode == .max && SubscriptionManager.shared.shouldGateMaxMode() {
                        onRequireUpgrade?()
                        return
                    } else {
                        withAnimation(DesignSystem.Animation.standard) {
                            selectedMode = mode
                        }
                        Haptics.impact(style: .light)
                    }
                }) {
                    Text(mode.displayName)
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundColor(selectedMode == mode ? .midnightNavy : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Group {
                                if selectedMode == mode {
                                    Color.primaryAccent
                                } else {
                                    Color.cardBackground
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                                .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        )
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }
        }
    }
}

struct ImageCard: View {
    let title: String
    let image: UIImage?
    let isLoading: Bool
    let onSelect: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.system(.headline, design: .default, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(Color.cardBackground)
                    .frame(height: 420)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .frame(maxHeight: 420)
                } else {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(.primaryAccent.opacity(0.4))
                        
                        if onSelect != nil {
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text("Upload your photo")
                                    .font(.system(.headline, design: .default, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Your upgrade starts here")
                                    .font(.system(.subheadline, design: .default))
                                    .foregroundColor(.textSecondary)
                                
                                Text("Takes ~5 seconds • HD results")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(.textSecondary)
                                    .padding(.top, DesignSystem.Spacing.xs)
                            }
                        }
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryAccent))
                }
            }
        }
        .onTapGesture {
            onSelect?()
        }
    }
}
