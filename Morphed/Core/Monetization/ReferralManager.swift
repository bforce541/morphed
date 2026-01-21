// Morphed/Core/Monetization/ReferralManager.swift

import Foundation

/// Simple referral system stub – local-only, no backend integration yet.
enum ReferralManager {
    private static let codeKey = "morphed_referral_code_v1"
    
    static var referralCode: String {
        if let existing = UserDefaults.standard.string(forKey: codeKey) {
            return existing
        }
        let new = generateCode()
        UserDefaults.standard.set(new, forKey: codeKey)
        return new
    }
    
    static func referralLink() -> URL? {
        // This can later be swapped for a real deep link / branch link.
        return URL(string: "https://morphed.app?ref=\(referralCode)")
    }
    
    private static func generateCode() -> String {
        let uuid = UUID().uuidString.prefix(8)
        return "MORPHE\(uuid)"
    }
}


