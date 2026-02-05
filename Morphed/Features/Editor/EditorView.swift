// morphed-ios/Morphed/Features/Editor/EditorView.swift

import SwiftUI
import PhotosUI

extension Notification.Name {
    static let editorClearImageAndReturn = Notification.Name("editorClearImageAndReturn")
}

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @AppStorage("morphed_default_edit_mode") private var defaultEditModeRaw = EditorViewModel.EditMode.presence.rawValue
    
    private var isFree: Bool {
        subscriptionManager.state.tier == .free
    }
    
    private var defaultEditMode: EditorViewModel.EditMode {
        EditorViewModel.EditMode(rawValue: defaultEditModeRaw) ?? .presence
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient - soft radial gradient matching History screen
                ZStack {
                    Color.backgroundBottom
                        .ignoresSafeArea()
                    
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.backgroundTop.opacity(0.6),
                            Color.backgroundBottom
                        ]),
                        center: .center,
                        startRadius: 100,
                        endRadius: 800
                    )
                    .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Top bar
                        HStack {
                            Text("Editor")
                                .font(.system(.largeTitle, design: .default, weight: .semibold))
                                .foregroundColor(.white)
                            
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
                        
                        // Original or Morphed Image Card
                        if viewModel.hasGeneratedPreview, let editedImage = viewModel.editedImage {
                            ImageCard(
                                title: "Morphed",
                                image: editedImage,
                                isLoading: false,
                                onSelect: nil,
                                onRemove: viewModel.isLoading ? nil : {
                                    Haptics.impact(style: .light)
                                    viewModel.clearSelectedImage()
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)

                            // Save / Export Buttons
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                MorphedButton(
                                    "Save Image",
                                    icon: "square.and.arrow.down",
                                    style: .primary
                                ) {
                                    Haptics.impact(style: .medium)
                                    Task {
                                        await viewModel.saveToPhotos()
                                    }
                                }

                                if isFree {
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
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        } else {
                            ImageCard(
                                title: "Original",
                                image: viewModel.originalImage,
                                isLoading: false,
                                onSelect: {
                                    Haptics.impact(style: .medium)
                                    viewModel.showImagePicker = true
                                },
                                onRemove: viewModel.isLoading ? nil : {
                                    Haptics.impact(style: .light)
                                    viewModel.clearSelectedImage()
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Mode Selector
                        if viewModel.originalImage != nil && !viewModel.hasGeneratedPreview {
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
                        if viewModel.originalImage != nil && !viewModel.hasGeneratedPreview {
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
                        if viewModel.editedImage != nil && !viewModel.hasGeneratedPreview {
                            ImageCard(
                                title: "Morphed",
                                image: viewModel.editedImage,
                                isLoading: false,
                                onSelect: nil,
                                onRemove: nil
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                            // Save / Export Buttons
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                MorphedButton(
                                    "Save Image",
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
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 88)
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

                // Precheck Warning Overlay
                if viewModel.showWarningPrompt, let warning = viewModel.warningMessage {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()

                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Photo Quality Warning")
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text(warning)
                            .font(.system(.subheadline, design: .default))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: DesignSystem.Spacing.sm) {
                            MorphedButton("Upgrade anyway", icon: "sparkles", style: .primary) {
                                viewModel.resolveWarningDecision(proceed: true)
                            }

                            MorphedButton("Retry", icon: "arrow.counterclockwise", style: .secondary) {
                                viewModel.resolveWarningDecision(proceed: false)
                                viewModel.clearSelectedImage()
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(Color.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showImagePicker, onDismiss: { viewModel.showImagePicker = false }) {
                ImagePicker(
                    selectedImage: Binding(
                        get: { viewModel.originalImage },
                        set: { viewModel.originalImage = $0 }
                    ),
                    onDismiss: { viewModel.showImagePicker = false }
                )
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.showPreviewModal && viewModel.editedImage != nil },
                set: { viewModel.showPreviewModal = $0 }
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
                Button("OK", role: .cancel) {
                    viewModel.clearSelectedImage()
                }
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
            .onChange(of: viewModel.originalImage) { newValue in
                if newValue != nil && viewModel.selectedMode == nil {
                    viewModel.selectedMode = defaultEditMode
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .editorClearImageAndReturn)) { _ in
                viewModel.clearSelectedImage()
                router.navigateToEditor()
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
    
    private let columns = [GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.sm) {
            ForEach(EditorViewModel.EditMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(DesignSystem.Animation.standard) {
                        selectedMode = mode
                    }
                    Haptics.impact(style: .light)
                    if SubscriptionManager.shared.shouldGateMode(mode) {
                        onRequireUpgrade?()
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(mode.displayName)
                            .font(.system(.subheadline, design: .default, weight: .semibold))
                    }
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
    let onRemove: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.system(.headline, design: .default, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            ZStack(alignment: .topTrailing) {
                let cardHeight: CGFloat = 420
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(Color.cardBackground)
                    .frame(height: cardHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: cardHeight - (DesignSystem.Spacing.sm * 2))
                        .padding(DesignSystem.Spacing.sm)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    
                    if let onRemove = onRemove {
                        Button(action: {
                            onRemove()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .padding(8)
                                .background(Color.cardBackground.opacity(0.9))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .buttonStyle(.plain)
                    }
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
                                
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
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
