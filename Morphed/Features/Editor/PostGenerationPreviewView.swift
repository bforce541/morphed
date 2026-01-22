// morphed-ios/Morphed/Features/Editor/PostGenerationPreviewView.swift

import SwiftUI

struct PostGenerationPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    let previewImage: UIImage
    let originalImage: UIImage?
    let mode: EditorViewModel.EditMode
    
    @State private var showUpgradeModal = false
    @State private var displayImage: UIImage
    
    init(previewImage: UIImage, originalImage: UIImage?, mode: EditorViewModel.EditMode) {
        self.previewImage = previewImage
        self.originalImage = originalImage
        self.mode = mode
        _displayImage = State(initialValue: previewImage)
    }
    
    private var isFree: Bool {
        subscriptionManager.state.tier == .free
    }
    
    var body: some View {
        ZStack {
            Color.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Preview Image
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: isFree ? 3 : 0)
                    .overlay(
                        // Watermark overlay for free users
                        Group {
                            if isFree {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text("MORPHED")
                                            .font(.system(size: 24, weight: .bold, design: .default))
                                            .foregroundColor(.white.opacity(0.9))
                                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                                            .padding(.trailing, 20)
                                            .padding(.bottom, 20)
                                    }
                                }
                            }
                        }
                    )
                
                // Bottom Actions
                VStack(spacing: DesignSystem.Spacing.sm) {
                    if isFree {
                        MorphedButton(
                            "Unlock Full Upgrade",
                            icon: "lock.open.fill",
                            style: .primary
                        ) {
                            Haptics.impact(style: .medium)
                            showUpgradeModal = true
                        }
                    } else {
                        MorphedButton(
                            "Save to Photos",
                            icon: "square.and.arrow.down",
                            style: .primary
                        ) {
                            Haptics.impact(style: .medium)
                            Task {
                                try? await PhotoSaver.saveImage(previewImage)
                            }
                        }
                    }
                    
                    Button(action: {
                        Haptics.impact(style: .light)
                        dismiss()
                    }) {
                        Text("Continue with preview")
                            .font(.system(.subheadline, design: .default, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(Color.backgroundBottom.opacity(0.95))
            }
        }
        .sheet(isPresented: $showUpgradeModal) {
            PostGenerationPaywallView()
        }
        .onAppear {
            // Auto-show upgrade modal for free users
            if isFree {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showUpgradeModal = true
                }
            }
        }
        .onChange(of: subscriptionManager.state.tier) { newTier in
            // When premium is unlocked, remove watermark and blur
            if newTier != .free, let original = originalImage {
                withAnimation(DesignSystem.Animation.standard) {
                    displayImage = original
                }
                showUpgradeModal = false
            }
        }
    }
}
