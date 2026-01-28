// Morphed/Config/StripeConfig.swift

import Foundation

enum StripeConfig {
    static let publishableKey = "pk_live_51Ssr3kE4W67XwMpcnBiyY8qjn6afGY335cC1eVwF300L6iT8l78tB1jpNlr9j8aAvdvisUS2tM6vc9H7wUc6ZBJV00DgQgQpaX"
    
    static let priceIdPro = "price_1Sud2gE4W67XwMpcgOpywVMM"
    static let priceIdPremium = "price_1Sud3JE4W67XwMpcvFWcuVBo"
    
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
}
