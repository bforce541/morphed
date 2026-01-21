// morphed-ios/Morphed/Core/Utils/AppColors.swift

import SwiftUI

extension Color {
    // Primary (Glow) - Cyber Cyan
    static let cyberCyan = Color(hex: "99F3FF")
    
    // Secondary (Accents) - Electric Blue
    static let electricBlue = Color(hex: "36A2EB")
    
    // Background (Deep) - Midnight Navy
    static let midnightNavy = Color(hex: "0B1B2B")
    
    // Surface (Cards/UI) - Deep Slate
    static let deepSlate = Color(hex: "1E2D3D")
    
    // Text (Readable) - Off-White
    static let offWhite = Color(hex: "E0E6ED")
    
    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

