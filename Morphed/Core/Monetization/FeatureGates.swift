// Morphed/Core/Monetization/FeatureGates.swift

import Foundation

/// Lightweight helper functions around SubscriptionManager
/// so views / view models don't need to know about tiers directly.
@MainActor
enum FeatureGates {
    static func canExportHD(_ manager: SubscriptionManager? = nil) -> Bool {
        let manager = manager ?? SubscriptionManager.shared
        return !manager.shouldGateHDExport()
    }
    
    static func shouldApplyWatermark(_ manager: SubscriptionManager? = nil) -> Bool {
        let manager = manager ?? SubscriptionManager.shared
        return manager.shouldApplyWatermark()
    }
}

