// Morphed/Core/Monetization/SubscriptionManager.swift

import Foundation
import Combine

/// High-level subscription / credits tier for the current device.
/// Monthly-only plans: proMonthly (Pro), premiumMonthly (Premium).
/// Backward compatibility: accepts old "weekly" and "monthlyPro" strings for migration, maps to new values.
enum SubscriptionTier: String, Codable {
    case free
    case proMonthly      // Pro (monthly)
    case premiumMonthly  // Premium (monthly)
    
    /// Backward compatibility: parse old tier strings and map to new ones.
    init?(rawValue: String) {
        switch rawValue {
        case "free":
            self = .free
        case "proMonthly", "weekly":  // Map old "weekly" to "proMonthly"
            self = .proMonthly
        case "premiumMonthly", "monthlyPro":  // Map old "monthlyPro" to "premiumMonthly"
            self = .premiumMonthly
        default:
            return nil
        }
    }
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
        case .proMonthly, .premiumMonthly:
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
    func recordMorph(isPremium: Bool, triggerPaywall: Bool = true) {
        state.totalMorphs += 1
        
        if state.tier == .free {
            state.freePreviewRenders += 1
            // Trigger paywall after the first successful preview.
            if triggerPaywall, state.freePreviewRenders == 1 {
                shouldPresentPaywall = true
            }
        }
        
        if isPremium {
            if entitlements.hasUnlimitedRenders {
                // Nothing to decrement.
            } else if state.remainingPremiumRenders > 0 {
                state.remainingPremiumRenders -= 1
                if triggerPaywall, state.remainingPremiumRenders == 0 {
                    shouldPresentPaywall = true
                }
            } else {
                if triggerPaywall {
                    shouldPresentPaywall = true
                }
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
    
    func purchaseProMonthlyMock() {
        state.tier = .proMonthly
        state.remainingPremiumRenders = .max
        state.hasCompletedMockPurchase = true
        persist()
    }
    
    func purchasePremiumMonthlyMock() {
        state.tier = .premiumMonthly
        state.remainingPremiumRenders = .max
        state.hasCompletedMockPurchase = true
        persist()
    }
    
    // Legacy method names (kept for backward compatibility)
    @available(*, deprecated, renamed: "purchaseProMonthlyMock")
    func purchaseWeeklyMock() {
        purchaseProMonthlyMock()
    }
    
    @available(*, deprecated, renamed: "purchasePremiumMonthlyMock")
    func purchaseMonthlyProMock() {
        purchasePremiumMonthlyMock()
    }
    
    /// Update subscription tier (e.g. after successful IAP + backend verify). Prefer refreshing from backend.
    func updateSubscriptionTier(_ tier: SubscriptionTier) {
        state.tier = tier
        state.remainingPremiumRenders = .max
        state.hasCompletedMockPurchase = true
        persist()
    }

    /// Apply backend entitlement response (source of truth). Use after fetch or IAP verify.
    func applyEntitlementResponse(_ response: EntitlementResponse) {
        let tier = SubscriptionTier(rawValue: response.tier) ?? .free
        state.tier = tier
        state.remainingPremiumRenders = response.remainingPremiumRenders ?? (tier == .free ? 0 : .max)
        if tier != .free {
            state.hasCompletedMockPurchase = true
        }
        persist()
    }

    /// Refresh entitlements from backend. Call on launch (with userId) and after IAP purchase/restore.
    func refreshEntitlements(userId: String) async {
        guard !userId.isEmpty else { return }
        do {
            let response = try await EntitlementService.fetchEntitlements(userId: userId)
            applyEntitlementResponse(response)
        } catch {
            // Keep existing local state on network failure (offline / migration-safe)
        }
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

