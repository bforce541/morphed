// morphed-ios/Morphed/Features/Onboarding/OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color.midnightNavy
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "sparkles",
                    title: "AI-Powered Editing",
                    description: "Transform your photos with advanced AI technology. Get professional results in seconds.",
                    gradient: [Color.electricBlue, Color.cyberCyan]
                )
                .tag(0)
                
                OnboardingPage(
                    icon: "slider.horizontal.3",
                    title: "Two Powerful Modes",
                    description: "Choose between MAX for dramatic enhancements or CLEAN for subtle, natural improvements.",
                    gradient: [Color.cyberCyan, Color.electricBlue]
                )
                .tag(1)
                
                OnboardingPage(
                    icon: "photo.on.rectangle",
                    title: "Save & Share",
                    description: "Save your creations to Photos and share them with the world. Build your perfect gallery.",
                    gradient: [Color.electricBlue, Color.cyberCyan]
                )
                .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            VStack {
                Spacer()
                
                if currentPage == 2 {
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
                        isPresented = false
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.midnightNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.electricBlue, Color.cyberCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .cyberCyan.opacity(0.5), radius: 10)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: icon)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.midnightNavy)
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.offWhite)
                
                Text(description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.offWhite.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

