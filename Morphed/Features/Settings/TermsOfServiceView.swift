// Morphed/Features/Settings/TermsOfServiceView.swift

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        // Title
                        Text("Morphed – Terms of Service")
                            .font(.system(.title, design: .default, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .padding(.bottom, DesignSystem.Spacing.xs)
                        
                        // Effective Date
                        Text("Effective Date: 1/28/2026")
                            .font(.system(.subheadline, design: .default))
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, DesignSystem.Spacing.md)
                        
                        // Introduction
                        Text("These Terms of Service (\"Terms\") govern your access to and use of the Morphed mobile application and related services (collectively, the \"Service\"), operated by Morphed (\"Morphed,\" \"we,\" \"us,\" or \"our\").")
                            .font(.system(.body, design: .default))
                            .foregroundColor(.textPrimary)
                            .padding(.bottom, DesignSystem.Spacing.sm)
                        
                        Text("By accessing or using the Service, you agree to be bound by these Terms. If you do not agree, you must not access or use the Service.")
                            .font(.system(.body, design: .default))
                            .foregroundColor(.textPrimary)
                            .padding(.bottom, DesignSystem.Spacing.lg)
                        
                        // Section 1: Eligibility
                        SectionView(
                            number: "1",
                            title: "Eligibility",
                            content: "You must be at least 13 years of age to use the Service. If you are under 18, you represent that you have obtained permission from a parent or legal guardian. You are solely responsible for ensuring compliance with applicable age restrictions in your jurisdiction."
                        )
                        
                        // Section 2: The Service
                        SectionView(
                            number: "2",
                            title: "The Service",
                            content: "Morphed provides AI-powered image enhancement and transformation tools. Outputs are generated algorithmically and are not guaranteed to be accurate, representative, or suitable for any specific purpose.\n\nWe reserve the right to modify, suspend, or discontinue any part of the Service at any time, with or without notice."
                        )
                        
                        // Section 3: Accounts and Responsibility
                        SectionView(
                            number: "3",
                            title: "Accounts and Responsibility",
                            content: "You are responsible for:\n\n• Maintaining the confidentiality of your account credentials\n• All activity occurring under your account\n• Providing accurate and current information\n\nMorphed is not responsible for unauthorized access resulting from your failure to secure your account."
                        )
                        
                        // Section 4: User Content
                        SectionView(
                            number: "4",
                            title: "User Content",
                            content: "You retain ownership of all images and content you upload (\"User Content\").\n\nBy using the Service, you grant Morphed a limited, non-exclusive, royalty-free, worldwide license to host, process, and analyze User Content solely for the purpose of providing the Service.\n\nMorphed does not claim ownership of your photos and does not use them for advertising purposes."
                        )
                        
                        // Section 5: Subscriptions and Payments
                        SectionView(
                            number: "5",
                            title: "Subscriptions and Payments",
                            content: "Certain features require a paid subscription.\n\n• Payments are processed by third-party platforms (e.g., Apple)\n• Subscriptions automatically renew unless canceled through the platform\n• Refunds are governed by the applicable app store's refund policy\n• Morphed does not control or issue refunds directly."
                        )
                        
                        // Section 6: Acceptable Use
                        SectionView(
                            number: "6",
                            title: "Acceptable Use",
                            content: "You agree not to:\n\n• Upload unlawful, harmful, misleading, or abusive content\n• Use the Service to impersonate others or engage in fraud\n• Reverse engineer, exploit, or interfere with the Service\n• Use the Service in violation of any applicable law or regulation\n\nWe reserve the right to investigate and take appropriate action, including account termination."
                        )
                        
                        // Section 7: Intellectual Property
                        SectionView(
                            number: "7",
                            title: "Intellectual Property",
                            content: "All software, algorithms, designs, branding, and materials associated with the Service are the exclusive property of Morphed and its licensors.\n\nYou may not copy, modify, distribute, or create derivative works without prior written consent."
                        )
                        
                        // Section 8: Disclaimers
                        SectionView(
                            number: "8",
                            title: "Disclaimers",
                            content: "The Service is provided \"as available\" and \"as is.\"\n\nMorphed makes no warranties, express or implied, regarding reliability, availability, accuracy, or suitability for any purpose."
                        )
                        
                        // Section 9: Limitation of Liability
                        SectionView(
                            number: "9",
                            title: "Limitation of Liability",
                            content: "To the fullest extent permitted by law, Morphed shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the Service."
                        )
                        
                        // Section 10: Termination
                        SectionView(
                            number: "10",
                            title: "Termination",
                            content: "Morphed may suspend or terminate your access at any time, with or without notice, for conduct that violates these Terms or is otherwise harmful to the Service or its users."
                        )
                        
                        // Section 11: Governing Law
                        SectionView(
                            number: "11",
                            title: "Governing Law",
                            content: "These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to conflict-of-law principles."
                        )
                        
                        // Section 12: Contact
                        SectionView(
                            number: "12",
                            title: "Contact",
                            content: "For questions regarding these Terms:\n📧 support@morphed-transform.com"
                        )
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Haptics.impact(style: .light)
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
        }
    }
}

struct SectionView: View {
    let number: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xs) {
                Text(number)
                    .font(.system(.headline, design: .default, weight: .bold))
                    .foregroundColor(.primaryAccent)
                
                Text(title)
                    .font(.system(.headline, design: .default, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            
            Text(content)
                .font(.system(.body, design: .default))
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, DesignSystem.Spacing.md)
    }
}
