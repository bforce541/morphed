// morphed-ios/Morphed/Core/Navigation/AppRouter.swift

import SwiftUI
import SafariServices
import Combine

class AppRouter: ObservableObject {
    static let shared = AppRouter()
    
    // Navigation state
    @Published var selectedTab: Int = 0
    @Published var showPaywall = false
    @Published var showSettings = false
    @Published var showPostGenerationPreview = false
    @Published var showPostGenerationPaywall = false
    
    // Support URLs
    private let supportEmail = "support@morphed.app"
    private let termsURL = URL(string: "https://morphed.app/terms")!
    private let privacyURL = URL(string: "https://morphed.app/privacy")!
    
    private init() {}
    
    // MARK: - Navigation Methods
    
    @MainActor
    func navigateToEditor() {
        selectedTab = 0
    }
    
    @MainActor
    func navigateToHistory() {
        selectedTab = 1
    }
    
    @MainActor
    func navigateToProfile() {
        selectedTab = 2
    }
    
    @MainActor
    func showPremium() {
        showPaywall = true
    }
    
    @MainActor
    func presentSettings() {
        showSettings = true
    }
    
    // MARK: - Support Actions
    
    func openSupportEmail() {
        if let url = URL(string: "mailto:\(supportEmail)?subject=Morphed%20Support") {
            UIApplication.shared.open(url)
        }
    }
    
    func openTerms() -> URL {
        return termsURL
    }
    
    func openPrivacy() -> URL {
        return privacyURL
    }
    
    func shareReferralLink() -> [Any] {
        let text = "I upgraded my photos with Morphed — try it out."
        if let link = ReferralManager.referralLink() {
            return [text, link]
        }
        return [text]
    }
}
