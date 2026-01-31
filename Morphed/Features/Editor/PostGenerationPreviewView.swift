// morphed-ios/Morphed/Features/Editor/PostGenerationPreviewView.swift

import SwiftUI
import UIKit

struct PostGenerationPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    let previewImage: UIImage
    let originalImage: UIImage?
    let mode: EditorViewModel.EditMode
    
    @State private var showUpgradeModal = false
    @State private var displayImage: UIImage
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorMessage: String?
    
    init(previewImage: UIImage, originalImage: UIImage?, mode: EditorViewModel.EditMode) {
        self.previewImage = previewImage
        self.originalImage = originalImage
        self.mode = mode
        _displayImage = State(initialValue: previewImage)
    }
    
    private var isFree: Bool {
        subscriptionManager.state.tier == .free
    }
    
    private var blurRadius: CGFloat {
        guard isFree else { return 0 }
        return 9
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
                    .blur(radius: blurRadius)
                
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
                                do {
                                    try await PhotoSaver.saveImage(previewImage)
                                    showSaveSuccess = true
                                    Haptics.notification(type: .success)
                                } catch {
                                    saveErrorMessage = error.localizedDescription
                                    showSaveError = true
                                    Haptics.notification(type: .error)
                                }
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
        .alert("Success", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) {
                NotificationCenter.default.post(name: .editorClearImageAndReturn, object: nil)
                router.navigateToEditor()
                dismiss()
            }
        } message: {
            Text("Image saved to Photos")
        }
        .alert("Error", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "An unknown error occurred")
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
