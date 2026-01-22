// morphed-ios/Morphed/Features/Onboarding/OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let totalPages = 3
    
    var body: some View {
        ZStack {
            // Background gradient
            Color.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.primaryAccent : Color.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xl)
                
                // Content
                TabView(selection: $currentPage) {
                    // Screen 1 - Identity Hook
                    OnboardingScreen1()
                        .tag(0)
                    
                    // Screen 2 - Value Priming
                    OnboardingScreen2()
                        .tag(1)
                    
                    // Screen 3 - Friction Remover + CTA
                    OnboardingScreen3(onComplete: completeOnboarding)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.standard, value: currentPage)
                
                // Navigation arrows
                HStack {
                    // Left arrow (only show on pages 1 and 2)
                    if currentPage > 0 {
                        Button(action: {
                            Haptics.impact(style: .light)
                            withAnimation(DesignSystem.Animation.standard) {
                                currentPage -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                        .opacity(0.6)
                    } else {
                        Spacer()
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    // Right arrow (show on pages 0 and 1)
                    if currentPage < totalPages - 1 {
                        Button(action: {
                            Haptics.impact(style: .light)
                            withAnimation(DesignSystem.Animation.standard) {
                                currentPage += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primaryAccent)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.primaryAccent.opacity(0.1))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    } else {
                        Spacer()
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
        Haptics.impact(style: .medium)
        isPresented = false
    }
}

// MARK: - Screen 1: Identity Hook
struct OnboardingScreen1: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 80, weight: .medium))
                .foregroundColor(.primaryAccent.opacity(0.8))
                .padding(.bottom, DesignSystem.Spacing.lg)
            
            // Title
            Text("Look like the upgraded version of you")
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Subtext
            Text("Dating · Socials · Professional presence")
                .font(.system(.headline, design: .default))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Micro-line
            Text("AI-powered photo upgrades in seconds")
                .font(.system(.caption, design: .default))
                .foregroundColor(.textSecondary.opacity(0.7))
                .padding(.top, DesignSystem.Spacing.sm)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Screen 2: Value Priming
struct OnboardingScreen2: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80, weight: .medium))
                .foregroundColor(.primaryAccent.opacity(0.8))
                .padding(.bottom, DesignSystem.Spacing.lg)
            
            // Title
            Text("Built for real-world results")
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Bullet points
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                BulletPoint(text: "MAX mode for dating profiles")
                BulletPoint(text: "CLEAN mode for professional photos")
                BulletPoint(text: "Studio-quality lighting & detail")
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.top, DesignSystem.Spacing.md)
            
            // Micro-line
            Text("Designed to enhance — not fake — your look")
                .font(.system(.caption, design: .default))
                .foregroundColor(.textSecondary.opacity(0.7))
                .padding(.top, DesignSystem.Spacing.md)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Screen 3: Friction Remover + CTA
struct OnboardingScreen3: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 80, weight: .medium))
                .foregroundColor(.primaryAccent.opacity(0.8))
                .padding(.bottom, DesignSystem.Spacing.lg)
            
            // Title
            Text("Try it free")
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Subtext
            Text("Get a preview upgrade.\nUnlock HD & MAX mode anytime.")
                .font(.system(.subheadline, design: .default))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.top, DesignSystem.Spacing.sm)
            
            Spacer()
            
            // Primary button
            MorphedButton(
                "Start",
                icon: "sparkles",
                style: .primary
            ) {
                onComplete()
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.sm)
            
            // Secondary button
            Button(action: {
                onComplete()
            }) {
                Text("Skip")
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Bullet Point Component
struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryAccent)
            
            Text(text)
                .font(.system(.body, design: .default))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
}
