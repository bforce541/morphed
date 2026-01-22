// morphed-ios/Morphed/Core/Utils/AppColors.swift

import SwiftUI

extension Color {
    // MARK: - Design System Colors
    
    // Primary Accent (Premium / CTA) - Cyan-Blue
    static let primaryAccent = Color(hex: "4FD1FF")
    
    // Secondary Accent (Muted) - Slate Blue
    static let secondaryAccent = Color(hex: "1E344A")
    
    // Background Gradient Colors
    static let backgroundTop = Color(hex: "071A2B")
    static let backgroundBottom = Color(hex: "030B14")
    
    // Card Background
    static let cardBackground = Color(hex: "0F2436").opacity(0.85)
    
    // Dividers
    static let divider = Color(hex: "1A2F44")
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let titleColor = Color(hex: "E6F1FA").opacity(0.9)
    
    // Legacy support (mapped to new system)
    static var cyberCyan: Color { primaryAccent }
    static var electricBlue: Color { primaryAccent }
    static var midnightNavy: Color { backgroundBottom }
    static var deepSlate: Color { secondaryAccent }
    static var offWhite: Color { textPrimary }
    
    // MARK: - Background Gradient
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
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

// MARK: - Design System Constants
enum DesignSystem {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    enum CornerRadius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
    }
    
    enum Animation {
        static let standard = SwiftUI.Animation.easeOut(duration: 0.25)
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)
    }
}

