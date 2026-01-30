// morphed-ios/Morphed/Features/Paywall/PostGenerationPaywallView.swift

import SwiftUI

struct PostGenerationPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var router = AppRouter.shared
    @StateObject private var authManager = AuthManager.shared
    
    @State private var selectedPlan: PricingPlanID = .proMonthly
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                        if let proMonthly = PricingModels.all.first(where: { $0.id == .proMonthly }) {
                            PricingCard(
                                plan: proMonthly,
                                isSelected: selectedPlan == .proMonthly,
                                isDominant: true
                            )
                            .onTapGesture {
                                withAnimation(DesignSystem.Animation.standard) {
                                    selectedPlan = .proMonthly
                                }
                                Haptics.impact(style: .light)
                            }
                        }
                        
                        if let premiumMonthly = PricingModels.all.first(where: { $0.id == .premiumMonthly }) {
                            PricingCard(
                                plan: premiumMonthly,
                                isSelected: selectedPlan == .premiumMonthly,
                                isDominant: false
                            )
                            .onTapGesture {
                                withAnimation(DesignSystem.Animation.standard) {
                                    selectedPlan = .premiumMonthly
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
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handlePurchase() {
        guard !isProcessing else { return }
        Haptics.impact(style: .medium)
        isProcessing = true

        Task {
            guard let productID = IAPProductID.productID(for: selectedPlan) else {
                isProcessing = false
                return
            }
            // Use Supabase UUID only (no email fallback).
            guard let userId = authManager.currentUser?.id, !userId.isEmpty else {
                errorMessage = "Please log in again to complete purchase sync."
                showError = true
                isProcessing = false
                return
            }

            switch await IAPManager.shared.purchase(productID: productID) {
            case .success(let payload):
                do {
                    let response = try await EntitlementService.verifyAppleTransaction(
                        userId: userId,
                        signedTransactionInfo: payload.jwsRepresentation,
                        environment: payload.environment
                    )
                    subscriptionManager.applyEntitlementResponse(response)
                    AnalyticsTracker.track("purchase_\(selectedPlan == .proMonthly ? "pro" : "premium")_post_gen", properties: nil)
                    Haptics.notification(type: .success)
                    dismiss()
                } catch {
                    errorMessage = "Purchase completed but sync failed: \(error.localizedDescription)"
                    showError = true
                    Haptics.notification(type: .error)
                }
            case .userCancelled:
                break
            case .pending:
                break
            case .failed:
                Haptics.notification(type: .error)
            }
            isProcessing = false
        }
    }
}
