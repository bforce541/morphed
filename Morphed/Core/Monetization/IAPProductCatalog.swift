// Morphed/Core/Monetization/IAPProductCatalog.swift
// Single source of truth for App Store subscription product IDs.
// Create matching products in App Store Connect: morphed_pro_monthly, morphed_premium_monthly.

import Foundation
import StoreKit

/// Apple subscription product IDs. Must match App Store Connect.
enum IAPProductID: String, CaseIterable {
    case proMonthly = "morphed_pro_monthly"
    case premiumMonthly = "morphed_premium_monthly"
}

/// Plan tier used by backend and SubscriptionManager.
/// Matches SubscriptionTier: proMonthly (Pro), premiumMonthly (Premium).
enum IAPPlanTier: String, Codable {
    case free
    case proMonthly      // Pro (monthly)
    case premiumMonthly  // Premium (monthly)
}

extension IAPProductID {
    /// Map product ID to internal plan tier for entitlement gating.
    var planTier: IAPPlanTier {
        switch self {
        case .proMonthly: return .proMonthly
        case .premiumMonthly: return .premiumMonthly
        }
    }

    /// All product IDs to load from StoreKit.
    static var subscriptionIDs: Set<String> {
        Set(IAPProductID.allCases.map(\.rawValue))
    }
}

/// Map UI plan (PricingPlanID) to Apple product ID.
extension IAPProductID {
    static func productID(for planID: PricingPlanID) -> IAPProductID? {
        switch planID {
        case .free: return nil
        case .proMonthly: return .proMonthly
        case .premiumMonthly: return .premiumMonthly
        }
    }
    
    /// Sanity check: verify product ID mapping is correct (prevents regressions).
    static func verifyMapping() {
        assert(productID(for: .proMonthly) == .proMonthly, "proMonthly must map to morphed_pro_monthly")
        assert(productID(for: .premiumMonthly) == .premiumMonthly, "premiumMonthly must map to morphed_premium_monthly")
        assert(productID(for: .free) == nil, "free must not map to any product")
    }
}
