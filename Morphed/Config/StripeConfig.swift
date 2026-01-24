// Morphed/Config/StripeConfig.swift

import Foundation

enum StripeConfig {
    static let publishableKey = "pk_test_51Ssr3pCiX5ufkuvRk6uzr5fTHuxvVWhaVvwPRq2Qcuri4ucygo3Vq1CmQobqU9PBW5rPTutZ4K2mR1bGFEtZCMQR0043NHh7O7"
    
    static let priceIdPro = "price_1SsrIJCiX5ufkuvRIYRTOlFl"
    static let priceIdPremium = "price_1SsrJ5CiX5ufkuvRWhGBOOsa"
    
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
