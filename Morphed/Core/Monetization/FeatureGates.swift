// Morphed/Core/Monetization/FeatureGates.swift

import Foundation

/// Lightweight helper functions around SubscriptionManager
/// so views / view models don't need to know about tiers directly.
enum FeatureGates {
    static func canUseMaxMode(_ manager: SubscriptionManager = .shared) -> Bool {
        !manager.shouldGateMaxMode()
    }
    
    static func canExportHD(_ manager: SubscriptionManager = .shared) -> Bool {
        !manager.shouldGateHDExport()
    }
    
    static func shouldApplyWatermark(_ manager: SubscriptionManager = .shared) -> Bool {
        manager.shouldApplyWatermark()
    }
}


