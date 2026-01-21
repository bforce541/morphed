// Morphed/Core/Monetization/AnalyticsTracker.swift

import Foundation

/// Simple analytics stub – prints events to the console.
/// Safe to remove or replace with a real analytics SDK later.
enum AnalyticsTracker {
    static func track(_ event: String, properties: [String: Any]? = nil) {
        #if DEBUG
        if let properties = properties {
            print("[Analytics] \(event): \(properties)")
        } else {
            print("[Analytics] \(event)")
        }
        #endif
    }
}


