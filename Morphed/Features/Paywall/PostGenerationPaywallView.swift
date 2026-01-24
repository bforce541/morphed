// morphed-ios/Morphed/Features/Paywall/PostGenerationPaywallView.swift

import SwiftUI

struct PostGenerationPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var router = AppRouter.shared
    
    @State private var selectedPlan: PricingPlanID = .weekly
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundBottom.opacity(0.95)
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundColor(.primaryAccent)
                        
                        Text("Your upgrade is ready")
                            .font(.system(.largeTitle, design: .default, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Remove watermark · Unlock HD · All 4 modes")
                            .font(.system(.subheadline, design: .default))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    // Pricing Cards (Simplified - just Pro and Premium)
                    VStack(spacing: DesignSystem.Spacing.md) {
                        if let weekly = PricingModels.all.first(where: { $0.id == .weekly }) {
                            PricingCard(
                                plan: weekly,
                                isSelected: selectedPlan == .weekly,
                                isDominant: true
                            )
                            .onTapGesture {
                                withAnimation(DesignSystem.Animation.standard) {
                                    selectedPlan = .weekly
                                }
                                Haptics.impact(style: .light)
                            }
                        }
                        
                        if let pro = PricingModels.all.first(where: { $0.id == .monthlyPro }) {
                            PricingCard(
                                plan: pro,
                                isSelected: selectedPlan == .monthlyPro,
                                isDominant: false
                            )
                            .onTapGesture {
                                withAnimation(DesignSystem.Animation.standard) {
                                    selectedPlan = .monthlyPro
                                }
                                Haptics.impact(style: .light)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // CTA Buttons
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        MorphedButton(
                            isProcessing ? "Processing..." : "Unlock Full Upgrade",
                            icon: isProcessing ? nil : "lock.open.fill",
                            style: .primary
                        ) {
                            handlePurchase()
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Button(action: {
                            Haptics.impact(style: .light)
                            dismiss()
                        }) {
                            Text("Continue with preview")
                                .font(.system(.subheadline, design: .default, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, DesignSystem.Spacing.xs)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, DesignSystem.Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        Haptics.impact(style: .light)
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
        }
    }
    
    private func handlePurchase() {
        Haptics.impact(style: .medium)
        isProcessing = true
        
        Task {
            let userId = AuthManager.shared.currentUser?.email ?? 
                        AuthManager.shared.currentUser?.id ?? 
                        "anonymous"
            
            await StripePaymentHandler.shared.presentCheckout(
                for: selectedPlan,
                userId: userId,
                onSuccess: {
                    let tier: SubscriptionTier = selectedPlan == .weekly ? .weekly : .monthlyPro
                    subscriptionManager.updateSubscriptionTier(tier)
                    AnalyticsTracker.track("purchase_\(selectedPlan == .weekly ? "pro" : "premium")_post_gen", properties: nil)
                    Haptics.notification(type: .success)
                    isProcessing = false
                    dismiss()
                },
                onFailure: { error in
                    print("Stripe checkout failed: \(error.localizedDescription)")
                    Haptics.notification(type: .error)
                    isProcessing = false
                }
            )
        }
    }
}
