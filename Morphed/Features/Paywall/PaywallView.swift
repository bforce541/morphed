// morphed-ios/Morphed/Features/Paywall/PaywallView.swift

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @State private var selectedPlan: PricingPlanID = .weekly
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.midnightNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        urgencyBanner
                        pricingGrid
                        footerCTA
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.offWhite)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            if UIImage(named: "AppLogo") != nil {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .shadow(color: .cyberCyan.opacity(0.5), radius: 20)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.cyberCyan)
                    .frame(width: 100, height: 100)
            }
            
            Text("Level Up Your Photos")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.offWhite)
            
            Text("Built for dating profiles, socials, and personal brand glow-ups.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.offWhite.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 32)
    }
    
    private var urgencyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundColor(.cyberCyan)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Launch pricing live")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.offWhite)
                Text("Limited-time founder discount before public release.")
                    .font(.system(size: 12))
                    .foregroundColor(.offWhite.opacity(0.6))
            }
            
            Spacer()
            
            Text("−40%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.midnightNavy)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.cyberCyan)
                .cornerRadius(999)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.deepSlate)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cyberCyan.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    private var pricingGrid: some View {
        VStack(spacing: 16) {
            ForEach(PricingModels.all, id: \.id.rawValue) { plan in
                PricingCard(
                    plan: plan,
                    isSelected: selectedPlan == plan.id
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedPlan = plan.id
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var footerCTA: some View {
        VStack(spacing: 12) {
            Button(action: handlePrimaryPurchase) {
                HStack {
                    Text(primaryButtonTitle(for: selectedPlan))
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Image(systemName: "lock.open.fill")
                }
                .foregroundColor(.midnightNavy)
                .padding(.horizontal, 20)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.electricBlue, Color.cyberCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
                .shadow(color: .cyberCyan.opacity(0.6), radius: 16, y: 4)
            }
            .padding(.horizontal, 20)
            
            Text("No real payments yet – this is a mocked purchase for development.")
                .font(.system(size: 11))
                .foregroundColor(.offWhite.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 8)
    }
    
    private func primaryButtonTitle(for planID: PricingPlanID) -> String {
        switch planID {
        case .free:
            return "Continue with Free Preview"
        case .weekly:
            return "Unlock Weekly Boost"
        case .monthlyPro:
            return "Upgrade to Pro Creator"
        case .oneTimePack:
            return "Buy 5 Premium Renders"
        case .earlyAccess:
            return "Join Early Access"
        }
    }
    
    private func handlePrimaryPurchase() {
        switch selectedPlan {
        case .free:
            AnalyticsTracker.track("paywall_continue_free", properties: nil)
            Haptics.selection()
            dismiss()
        case .weekly:
            subscriptionManager.purchaseWeeklyMock()
            AnalyticsTracker.track("purchase_weekly_mock", properties: nil)
        case .monthlyPro:
            subscriptionManager.purchaseMonthlyProMock()
            AnalyticsTracker.track("purchase_monthly_mock", properties: nil)
        case .oneTimePack:
            subscriptionManager.purchaseOneTimePackMock()
            AnalyticsTracker.track("purchase_one_time_pack_mock", properties: nil)
        case .earlyAccess:
            subscriptionManager.purchaseEarlyAccessMock()
            AnalyticsTracker.track("purchase_early_access_mock", properties: nil)
        }
        
        Haptics.notification(type: .success)
        dismiss()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.cyberCyan)
                .frame(width: 44, height: 44)
                .background(Color.deepSlate)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyberCyan.opacity(0.3), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.offWhite)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.offWhite.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.deepSlate)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyberCyan.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PricingCard: View {
    let plan: PricingPlan
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.offWhite)
                    Text(plan.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.offWhite.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.priceText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.cyberCyan)
                    if let badge = plan.badgeText {
                        Text(badge.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.midnightNavy)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyberCyan)
                            .cornerRadius(999)
                    }
                }
            }
            
            ForEach(plan.bulletPoints, id: \.self) { bullet in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.cyberCyan.opacity(0.9))
                    Text(bullet)
                        .font(.system(size: 12))
                        .foregroundColor(.offWhite.opacity(0.7))
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(plan.isHighlighted ? Color.deepSlate.opacity(0.9) : Color.deepSlate)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isSelected ? Color.cyberCyan : Color.cyberCyan.opacity(plan.isHighlighted ? 0.4 : 0.15),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: isSelected ? .cyberCyan.opacity(0.4) : .clear, radius: 12, y: 4)
    }
}


