// morphed-ios/Morphed/Features/Paywall/PaywallView.swift

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var authManager = AuthManager.shared
    
    @State private var selectedPlan: PricingPlanID = .weekly
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        header
                        
                        // Pricing Cards (Pro first, then Premium, then Free)
                        pricingCards
                        
                        // CTA Button
                        footerCTA
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
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
            .alert("Checkout Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Unlock your upgraded photo")
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("HD results · No watermark · Presence, Physique, Face & Style modes")
                .font(.system(.subheadline, design: .default))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.top, DesignSystem.Spacing.lg)
    }
    
    private var pricingCards: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Pro - Dominant
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
            
            // Premium - Neutral
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
            
            // Free - Muted, Last
            if let free = PricingModels.all.first(where: { $0.id == .free }) {
                PricingCard(
                    plan: free,
                    isSelected: selectedPlan == .free,
                    isDominant: false
                )
                .onTapGesture {
                    withAnimation(DesignSystem.Animation.standard) {
                        selectedPlan = .free
                    }
                    Haptics.impact(style: .light)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    private var footerCTA: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            MorphedButton(
                isProcessing ? "Processing..." : primaryButtonTitle(for: selectedPlan),
                icon: isProcessing || selectedPlan == .free ? nil : "lock.open.fill",
                style: .primary
            ) {
                handlePrimaryPurchase()
            }
            .disabled(isProcessing)
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            if let plan = PricingModels.all.first(where: { $0.id == selectedPlan }),
               let cancelText = plan.cancelText {
                Text(cancelText)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
            
        }
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    private func primaryButtonTitle(for planID: PricingPlanID) -> String {
        switch planID {
        case .free:
            return "Continue with Preview"
        case .weekly:
            return "Unlock Pro"
        case .monthlyPro:
            return "Upgrade to Premium"
        }
    }
    
    private func handlePrimaryPurchase() {
        guard !isProcessing else { return }
        
        Haptics.impact(style: .medium)
        isProcessing = true
        
        Task {
            switch selectedPlan {
            case .free:
                AnalyticsTracker.track("paywall_continue_free", properties: nil)
                isProcessing = false
                dismiss()
                
            case .weekly, .monthlyPro:
                let userId = authManager.currentUser?.email ?? 
                            authManager.currentUser?.id ?? 
                            "anonymous"
                
                await StripePaymentHandler.shared.presentCheckout(
                    for: selectedPlan,
                    userId: userId,
                    onSuccess: {
                        let tier: SubscriptionTier = selectedPlan == .weekly ? .weekly : .monthlyPro
                        subscriptionManager.updateSubscriptionTier(tier)
                        AnalyticsTracker.track("purchase_\(selectedPlan == .weekly ? "pro" : "premium")", properties: nil)
                        Haptics.notification(type: .success)
                        isProcessing = false
                        dismiss()
                    },
                    onFailure: { error in
                        print("Stripe checkout failed: \(error.localizedDescription)")
                        errorMessage = error.localizedDescription
                        showError = true
                        Haptics.notification(type: .error)
                        isProcessing = false
                    }
                )
            }
        }
    }
}

struct PricingCard: View {
    let plan: PricingPlan
    let isSelected: Bool
    let isDominant: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header with badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(plan.title)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        if let badge = plan.badgeText, isDominant {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .default))
                                .foregroundColor(.midnightNavy)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primaryAccent)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(plan.subtitle)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text(plan.priceText)
                    .font(.system(.headline, design: .default, weight: .bold))
                    .foregroundColor(.primaryAccent)
            }
            
            // Bullet points
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                ForEach(plan.bulletPoints, id: \.self) { bullet in
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryAccent)
                        Text(bullet)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(
                    isSelected ? Color.primaryAccent : (isDominant ? Color.primaryAccent.opacity(0.5) : Color.divider.opacity(0.3)),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: isSelected && isDominant ? .primaryAccent.opacity(0.3) : .clear,
            radius: isSelected && isDominant ? 16 : 0,
            y: isSelected && isDominant ? 4 : 0
        )
        .scaleEffect(isSelected && isDominant ? 1.02 : 1.0)
    }
}
