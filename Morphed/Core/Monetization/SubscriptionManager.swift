// Morphed/Core/Monetization/SubscriptionManager.swift

import Foundation
import Combine

/// High-level subscription / credits tier for the current device.
/// This is intentionally local-only and uses UserDefaults – no real auth or billing.
enum SubscriptionTier: String, Codable {
    case free
    case weekly
    case monthlyPro
}

struct SubscriptionState: Codable {
    var tier: SubscriptionTier
    
    /// Remaining premium renders (for packs / early access).
    var remainingPremiumRenders: Int
    
    /// Total morphs performed on this device.
    var totalMorphs: Int
    
    /// Number of free preview renders that have been completed.
    var freePreviewRenders: Int
    
    /// Whether the user has ever completed a mock purchase.
    var hasCompletedMockPurchase: Bool
}

/// Simple feature flags derived from the current subscription state.
struct Entitlements {
    let canUseAllUpgradeModes: Bool
    let canRemoveWatermark: Bool
    let canExportHD: Bool
    let hasUnlimitedRenders: Bool
    let remainingPremiumRenders: Int
    
    /// Free tier: 1 preview, Presence only, watermarked, no HD.
    static func free(remainingPremiumRenders: Int) -> Entitlements {
        Entitlements(
            canUseAllUpgradeModes: false,
            canRemoveWatermark: false,
            canExportHD: false,
            hasUnlimitedRenders: false,
            remainingPremiumRenders: remainingPremiumRenders
        )
    }
}

/// Central place for monetization state & feature gating.
/// This is deliberately conservative and does NOT talk to real billing.
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var state: SubscriptionState
    @Published var shouldPresentPaywall: Bool = false
    
    private let storageKey = "morphed_subscription_state_v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? decoder.decode(SubscriptionState.self, from: data) {
            state = decoded
        } else {
            state = SubscriptionState(
                tier: .free,
                remainingPremiumRenders: 0,
                totalMorphs: 0,
                freePreviewRenders: 0,
                hasCompletedMockPurchase: false
            )
        }
    }
    
    var entitlements: Entitlements {
        switch state.tier {
        case .free:
            return .free(remainingPremiumRenders: state.remainingPremiumRenders)
        case .weekly:
            return Entitlements(
                canUseAllUpgradeModes: true,
                canRemoveWatermark: true,
                canExportHD: true,
                hasUnlimitedRenders: true,
                remainingPremiumRenders: .max
            )
        case .monthlyPro:
            return Entitlements(
                canUseAllUpgradeModes: true,
                canRemoveWatermark: true,
                canExportHD: true,
                hasUnlimitedRenders: true,
                remainingPremiumRenders: .max
            )
        }
    }
    
    /// Record that a morph was completed.
    /// - Parameter isPremium: whether this should consume a premium credit.
    func recordMorph(isPremium: Bool) {
        state.totalMorphs += 1
        
        if state.tier == .free {
            state.freePreviewRenders += 1
            // Trigger paywall after the first successful preview.
            if state.freePreviewRenders == 1 {
                shouldPresentPaywall = true
            }
        }
        
        if isPremium {
            if entitlements.hasUnlimitedRenders {
                // Nothing to decrement.
            } else if state.remainingPremiumRenders > 0 {
                state.remainingPremiumRenders -= 1
                if state.remainingPremiumRenders == 0 {
                    shouldPresentPaywall = true
                }
            } else {
                shouldPresentPaywall = true
            }
        }
        
        persist()
    }
    
    /// Whether selecting the given mode should be gated (free: Presence only; premium: all 4).
    func shouldGateMode(_ mode: EditorViewModel.EditMode) -> Bool {
        if mode == .presence { return false }
        return !entitlements.canUseAllUpgradeModes
    }
    
    /// Whether saving / exporting should be HD-gated.
    func shouldGateHDExport() -> Bool {
        !entitlements.canExportHD
    }
    
    /// Whether a watermark overlay should be applied for the current user.
    func shouldApplyWatermark() -> Bool {
        !entitlements.canRemoveWatermark
    }
    
    /// Reset the "present paywall" flag after the UI has shown it.
    func consumePaywallTrigger() {
        shouldPresentPaywall = false
    }
    
    // MARK: - Purchases
    
    func purchaseWeeklyMock() {
        state.tier = .weekly
        state.remainingPremiumRenders = .max
        state.hasCompletedMockPurchase = true
        persist()
    }
    
    func purchaseMonthlyProMock() {
        state.tier = .monthlyPro
        state.remainingPremiumRenders = .max
        state.hasCompletedMockPurchase = true
        persist()
    }
    
    /// Update subscription tier after successful Stripe purchase
    func updateSubscriptionTier(_ tier: SubscriptionTier) {
        state.tier = tier
        state.remainingPremiumRenders = .max
        state.hasCompletedMockPurchase = true
        persist()
    }
    
    
    func resetToFree() {
        state = SubscriptionState(
            tier: .free,
            remainingPremiumRenders: 0,
            totalMorphs: 0,
            freePreviewRenders: 0,
            hasCompletedMockPurchase: false
        )
        persist()
    }
    
    // MARK: - Persistence
    
    private func persist() {
        if let data = try? encoder.encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}


