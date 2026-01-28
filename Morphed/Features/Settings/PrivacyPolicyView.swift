// Morphed/Features/Settings/PrivacyPolicyView.swift

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        // Title
                        Text("Morphed – Privacy Policy")
                            .font(.system(.title, design: .default, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .padding(.bottom, DesignSystem.Spacing.xs)
                        
                        // Effective Date
                        Text("Effective Date: 1/28/2026")
                            .font(.system(.subheadline, design: .default))
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, DesignSystem.Spacing.md)
                        
                        // Introduction
                        Text("This Privacy Policy explains how Morphed collects, uses, and protects information when you use the Service.")
                            .font(.system(.body, design: .default))
                            .foregroundColor(.textPrimary)
                            .padding(.bottom, DesignSystem.Spacing.lg)
                        
                        // Section 1: Information We Collect
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xs) {
                                Text("1")
                                    .font(.system(.headline, design: .default, weight: .bold))
                                    .foregroundColor(.primaryAccent)
                                
                                Text("Information We Collect")
                                    .font(.system(.headline, design: .default, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Text("Information You Provide")
                                .font(.system(.subheadline, design: .default, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .padding(.top, DesignSystem.Spacing.xs)
                            
                            Text("• Account identifiers (e.g., email address)\n• Images uploaded for processing\n• Subscription status and preferences")
                                .font(.system(.body, design: .default))
                                .foregroundColor(.textPrimary)
                                .padding(.leading, DesignSystem.Spacing.sm)
                            
                            Text("Automatically Collected Information")
                                .font(.system(.subheadline, design: .default, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .padding(.top, DesignSystem.Spacing.sm)
                            
                            Text("• Device and operating system information\n• Usage metrics and interaction data\n• Diagnostic and performance logs")
                                .font(.system(.body, design: .default))
                                .foregroundColor(.textPrimary)
                                .padding(.leading, DesignSystem.Spacing.sm)
                        }
                        .padding(.bottom, DesignSystem.Spacing.md)
                        
                        // Section 2: Use of Information
                        SectionView(
                            number: "2",
                            title: "Use of Information",
                            content: "We use collected information to:\n\n• Operate and improve the Service\n• Process images and deliver results\n• Manage subscriptions and support requests\n• Maintain security and prevent misuse"
                        )
                        
                        // Section 3: Image Processing
                        SectionView(
                            number: "3",
                            title: "Image Processing",
                            content: "Uploaded images are processed only to fulfill user-requested functionality.\n\n• Images are not sold\n• Images are not used for marketing\n• Temporary storage may occur for processing and quality assurance"
                        )
                        
                        // Section 4: Data Sharing
                        SectionView(
                            number: "4",
                            title: "Data Sharing",
                            content: "We may share limited data with:\n\n• Cloud infrastructure and analytics providers\n• Payment processors\n• Legal authorities where required by law\n\nWe do not sell personal information."
                        )
                        
                        // Section 5: Data Retention
                        SectionView(
                            number: "5",
                            title: "Data Retention",
                            content: "Information is retained only for as long as necessary to:\n\n• Provide the Service\n• Comply with legal obligations\n• Resolve disputes and enforce agreements"
                        )
                        
                        // Section 6: Data Protection
                        SectionView(
                            number: "6",
                            title: "Data Protection",
                            content: "Morphed implements administrative, technical, and organizational measures designed to protect information against unauthorized access, disclosure, or misuse."
                        )
                        
                        // Section 7: User Rights
                        SectionView(
                            number: "7",
                            title: "User Rights",
                            content: "Depending on your jurisdiction, you may have rights to:\n\n• Access personal data\n• Request correction or deletion\n• Restrict certain processing activities\n\nRequests may be submitted via email."
                        )
                        
                        // Section 8: Children's Privacy
                        SectionView(
                            number: "8",
                            title: "Children's Privacy",
                            content: "The Service is not directed toward children under 13, and we do not knowingly collect their personal information."
                        )
                        
                        // Section 9: Policy Updates
                        SectionView(
                            number: "9",
                            title: "Policy Updates",
                            content: "This Privacy Policy may be updated periodically. Continued use of the Service constitutes acceptance of the revised policy."
                        )
                        
                        // Section 10: Contact
                        SectionView(
                            number: "10",
                            title: "Contact",
                            content: "📧 support@morphed-transform.com"
                        )
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Privacy Policy")
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
