// morphed-ios/Morphed/Core/Utils/DesignComponents.swift

import SwiftUI

// MARK: - MorphedCard
struct MorphedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(Color.divider.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - MorphedButton
struct MorphedButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            Haptics.impact(style: .medium)
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(.headline, design: .default, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .opacity(isEnabled ? 1 : 0.9)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(1)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? .midnightNavy : .midnightNavy.opacity(0.9)
        case .secondary:
            return isEnabled ? .textPrimary : .textPrimary.opacity(0.85)
        case .destructive:
            return isEnabled ? .textPrimary : .textPrimary.opacity(0.85)
        }
    }
    
    private var backgroundColor: some View {
        Group {
            switch style {
            case .primary:
                Color.primaryAccent
                    .opacity(isEnabled ? 1 : 0.75)
            case .secondary:
                Color.cardBackground
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                    )
            case .destructive:
                Color.cardBackground
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - SectionHeader
struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(.caption, design: .default, weight: .semibold))
            .foregroundColor(.textSecondary.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - PremiumBadge
struct PremiumBadge: View {
    let size: BadgeSize
    
    enum BadgeSize {
        case small
        case medium
        case large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: size.fontSize - 2, weight: .semibold))
            Text("PRO")
                .font(.system(size: size.fontSize, weight: .bold, design: .default))
        }
        .foregroundColor(.midnightNavy)
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding / 2)
        .background(Color.primaryAccent)
        .cornerRadius(8)
    }
}

// MARK: - Divider
struct MorphedDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.divider.opacity(0.3))
            .frame(height: 1)
    }
}
