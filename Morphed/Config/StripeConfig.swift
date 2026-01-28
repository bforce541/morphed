// Morphed/Config/StripeConfig.swift

import Foundation

enum StripeConfig {
    static let publishableKey = "pk_live_51Ssr3kE4W67XwMpcnBiyY8qjn6afGY335cC1eVwF300L6iT8l78tB1jpNlr9j8aAvdvisUS2tM6vc9H7wUc6ZBJV00DgQgQpaX"
    
    static let priceIdPro = requireInfoPlistValue("STRIPE_PRICE_ID_PRO")
    static let priceIdPremium = requireInfoPlistValue("STRIPE_PRICE_ID_PREMIUM")
    
    static func priceId(for planID: PricingPlanID) -> String? {
        switch planID {
        case .free:
            return nil
        case .weekly:
            return priceIdPro
        case .monthlyPro:
            return priceIdPremium
        }
    }

    private static func requireInfoPlistValue(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Missing \(key) in Info.plist")
        }
        return value
    }
}
