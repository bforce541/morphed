// Morphed/Core/Monetization/PricingModels.swift

import Foundation

enum PricingPlanID: String {
    case free
    case proMonthly      // Pro (monthly billing)
    case premiumMonthly  // Premium (monthly billing)
}

struct PricingPlan {
    let id: PricingPlanID
    let title: String
    let subtitle: String
    let priceText: String
    let badgeText: String?
    let isHighlighted: Bool
    let bulletPoints: [String]
    let isMostPopular: Bool
    let cancelText: String?
}

enum PricingModels {
    static let free = PricingPlan(
        id: .free,
        title: "Free",
        subtitle: "Preview only",
        priceText: "$0",
        badgeText: nil,
        isHighlighted: false,
        bulletPoints: [
            "Low-res preview render",
            "Presence mode only",
            "Watermark",
            "Standard queue"
        ],
        isMostPopular: false,
        cancelText: nil
    )
    
    static let proMonthly = PricingPlan(
        id: .proMonthly,
        title: "Pro",
        subtitle: "Unlimited HD morphs",
        priceText: "$6.99 / month",
        badgeText: "MOST POPULAR",
        isHighlighted: true,
        bulletPoints: [
            "Unlimited HD morphs",
            "All 4 upgrade modes (Presence, Physique, Face, Style)",
            "No watermark",
            "Priority queue"
        ],
        isMostPopular: true,
        cancelText: "Cancel anytime · No questions asked"
    )
    
    static let premiumMonthly = PricingPlan(
        id: .premiumMonthly,
        title: "Premium",
        subtitle: "For creators & power users",
        priceText: "$11.99 / month",
        badgeText: nil,
        isHighlighted: false,
        bulletPoints: [
            "Everything in Pro",
            "Creator presets (dating, social, brand)",
            "Higher generation limits"
        ],
        isMostPopular: false,
        cancelText: "Cancel anytime · No questions asked"
    )
    
    static let all: [PricingPlan] = [
        proMonthly,      // Most popular first
        premiumMonthly,
        free         // Free last
    ]
}
