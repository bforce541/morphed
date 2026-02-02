// morphed-ios/Morphed/Features/Paywall/PostGenerationPaywallView.swift

import SwiftUI

struct PostGenerationPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var router = AppRouter.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var iapManager = IAPManager.shared
    
    @State private var selectedPlan: PricingPlanID = .proMonthly
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pendingTransactionPayload: VerifiedTransactionPayload? = nil
    @State private var showRetrySync = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundBottom.opacity(0.95)
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    Spacer()
                    
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
                    
                    if iapManager.isLoadingProducts && iapManager.products.isEmpty {
                        ProgressView("Loading plans…")
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryAccent))
                            .padding(.vertical, DesignSystem.Spacing.lg)
                    } else {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            if let proMonthly = PricingModels.all.first(where: { $0.id == .proMonthly }) {
                                PricingCard(
                                    plan: proMonthly,
                                    displayPriceOverride: iapManager.priceString(for: .proMonthly).map { "\($0) / month" },
                                    isSelected: selectedPlan == .proMonthly,
                                    isDominant: true
                                )
                                .onTapGesture {
                                    withAnimation(DesignSystem.Animation.standard) { selectedPlan = .proMonthly }
                                    Haptics.impact(style: .light)
                                }
                            }
                            if let premiumMonthly = PricingModels.all.first(where: { $0.id == .premiumMonthly }) {
                                PricingCard(
                                    plan: premiumMonthly,
                                    displayPriceOverride: iapManager.priceString(for: .premiumMonthly).map { "\($0) / month" },
                                    isSelected: selectedPlan == .premiumMonthly,
                                    isDominant: false
                                )
                                .onTapGesture {
                                    withAnimation(DesignSystem.Animation.standard) { selectedPlan = .premiumMonthly }
                                    Haptics.impact(style: .light)
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
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
                        
                        Button(action: { handleRestorePurchases() }) {
                            Text("Restore Purchases")
                                .font(.system(.subheadline, design: .default, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .disabled(isProcessing)
                        .padding(.top, DesignSystem.Spacing.xs)
                        
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
            .alert("Purchase Status", isPresented: $showError) {
                if showRetrySync {
                    Button("Retry Sync") { handleRetrySync() }
                    Button("Restore Purchases") { handleRestorePurchases() }
                    Button("Cancel", role: .cancel) {
                        pendingTransactionPayload = nil
                        showRetrySync = false
                    }
                } else {
                    Button("OK", role: .cancel) { }
                }
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
                errorMessage = "Product not available"
                showError = true
                isProcessing = false
                return
            }
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
                    await subscriptionManager.refreshEntitlements(userId: userId)
                    AnalyticsTracker.track("purchase_\(selectedPlan == .proMonthly ? "pro" : "premium")_post_gen", properties: nil)
                    Haptics.notification(type: .success)
                    isProcessing = false
                    dismiss()
                } catch {
                    pendingTransactionPayload = payload
                    errorMessage = "Purchase completed. Syncing access failed. Tap 'Retry Sync'."
                    showRetrySync = true
                    showError = true
                    Haptics.notification(type: .error)
                    isProcessing = false
                }
            case .userCancelled:
                isProcessing = false
            case .pending:
                errorMessage = "Purchase is pending (e.g. Ask to Buy). You'll get access when it's approved."
                showError = true
                isProcessing = false
            case .failed(let error):
                errorMessage = error.localizedDescription
                showError = true
                Haptics.notification(type: .error)
                isProcessing = false
            }
        }
    }

    private func handleRestorePurchases() {
        guard !isProcessing else { return }
        guard let userId = authManager.currentUser?.id, !userId.isEmpty else {
            errorMessage = "Please log in to restore purchases."
            showError = true
            return
        }
        isProcessing = true
        Task {
            switch await IAPManager.shared.restorePurchases() {
            case .success:
                let payloads = await IAPManager.shared.allCurrentEntitlementPayloads()
                for payload in payloads {
                    do {
                        let response = try await EntitlementService.verifyAppleTransaction(
                            userId: userId,
                            signedTransactionInfo: payload.jwsRepresentation,
                            environment: payload.environment
                        )
                        subscriptionManager.applyEntitlementResponse(response)
                    } catch { /* continue with next */ }
                }
                await subscriptionManager.refreshEntitlements(userId: userId)
                AnalyticsTracker.track("restore_purchases_success", properties: nil)
                Haptics.notification(type: .success)
                dismiss()
            case .noPurchasesToRestore:
                errorMessage = "No purchases to restore."
                showError = true
            case .failed(let error):
                errorMessage = error.localizedDescription
                showError = true
                Haptics.notification(type: .error)
            }
            isProcessing = false
        }
    }

    private func handleRetrySync() {
        guard let payload = pendingTransactionPayload,
              let userId = authManager.currentUser?.id, !userId.isEmpty else {
            errorMessage = "Please log in again to complete purchase sync."
            showError = true
            return
        }
        isProcessing = true
        showRetrySync = false
        Task {
            do {
                let response = try await EntitlementService.verifyAppleTransaction(
                    userId: userId,
                    signedTransactionInfo: payload.jwsRepresentation,
                    environment: payload.environment
                )
                subscriptionManager.applyEntitlementResponse(response)
                await subscriptionManager.refreshEntitlements(userId: userId)
                pendingTransactionPayload = nil
                AnalyticsTracker.track("purchase_retry_sync_success", properties: nil)
                Haptics.notification(type: .success)
                isProcessing = false
                dismiss()
            } catch {
                errorMessage = "Sync failed: \(error.localizedDescription). Try 'Restore Purchases'."
                showRetrySync = true
                showError = true
                Haptics.notification(type: .error)
                isProcessing = false
            }
        }
    }
}
