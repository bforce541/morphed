// Morphed/Core/Monetization/PricingModels.swift

import Foundation

enum PricingPlanID: String {
    case free
    case weekly
    case monthlyPro
    case oneTimePack
    case earlyAccess
}

struct PricingPlan {
    let id: PricingPlanID
    let title: String
    let subtitle: String
    let priceText: String
    let badgeText: String?
    let isHighlighted: Bool
    let bulletPoints: [String]
}

enum PricingModels {
    static let free = PricingPlan(
        id: .free,
        title: "Free",
        subtitle: "Try Morphed with a preview render",
        priceText: "$0",
        badgeText: "Start here",
        isHighlighted: false,
        bulletPoints: [
            "1 low-res preview render",
            "CLEAN mode only",
            "Morphed watermark",
            "Standard queue"
        ]
    )
    
    static let weekly = PricingPlan(
        id: .weekly,
        title: "Weekly Boost",
        subtitle: "Best for dating app glow-ups",
        priceText: "$9.99 / week",
        badgeText: "Most Popular",
        isHighlighted: true,
        bulletPoints: [
            "Unlimited HD morphs",
            "MAX + CLEAN modes",
            "No watermark",
            "Priority queue"
        ]
    )
    
    static let monthlyPro = PricingPlan(
        id: .monthlyPro,
        title: "Pro Creator",
        subtitle: "For personal brand & content",
        priceText: "$29 / month",
        badgeText: "Power Users",
        isHighlighted: false,
        bulletPoints: [
            "All Weekly features",
            "Dating pack presets",
            "Social pack presets",
            "Branding pack presets"
        ]
    )
    
    static let oneTimePack = PricingPlan(
        id: .oneTimePack,
        title: "5 Renders Pack",
        subtitle: "No subscription",
        priceText: "$19 one-time",
        badgeText: "No Commitment",
        isHighlighted: false,
        bulletPoints: [
            "5 premium renders",
            "MAX + CLEAN modes",
            "No watermark"
        ]
    )
    
    static let earlyAccess = PricingPlan(
        id: .earlyAccess,
        title: "Founder Access",
        subtitle: "Support the launch",
        priceText: "$19 presale",
        badgeText: "Limited",
        isHighlighted: false,
        bulletPoints: [
            "10 premium renders",
            "Founder badge",
            "Early feature access"
        ]
    )
    
    static let all: [PricingPlan] = [
        free,
        weekly,
        monthlyPro,
        oneTimePack,
        earlyAccess
    ]
}


