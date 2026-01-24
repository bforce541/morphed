// Morphed/Core/Monetization/StripePaymentHandler.swift

import Foundation
import UIKit
import SafariServices

@MainActor
class StripePaymentHandler: NSObject {
    static let shared = StripePaymentHandler()
    
    /// Topmost view controller in the presentation hierarchy (handles sheets, modals, etc.)
    private static var topViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow })
                ?? windowScene.windows.first,
              let root = window.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    private var safariViewController: SFSafariViewController?
    private var onSuccess: (() -> Void)?
    private var onFailure: ((Error) -> Void)?
    private var currentPlanID: PricingPlanID?
    
    private override init() {
        super.init()
    }
    
    func presentCheckout(
        for planID: PricingPlanID,
        userId: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) async {
        guard let priceId = StripeConfig.priceId(for: planID) else {
            onFailure(StripeError.invalidPriceId)
            return
        }
        
        self.currentPlanID = planID
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        
        do {
            let session = try await StripeService.createCheckoutSession(priceId: priceId, userId: userId)
            
            guard let checkoutURL = URL(string: session.url) else {
                onFailure(StripeError.invalidResponse)
                return
            }
            
            let safariVC = SFSafariViewController(url: checkoutURL)
            safariVC.delegate = self
            self.safariViewController = safariVC
            
            guard let presenter = Self.topViewController else {
                onFailure(StripeError.serverError("Could not find view to present checkout"))
                return
            }
            presenter.present(safariVC, animated: true)
        } catch {
            onFailure(error)
        }
    }
    
    func handleDeepLink(url: URL) {
        guard url.scheme == "morphed" else { return }
        
        if url.host == "stripe-success" {
            safariViewController?.dismiss(animated: true) {
                if let planID = self.currentPlanID {
                    let tier: SubscriptionTier = planID == .weekly ? .weekly : .monthlyPro
                    SubscriptionManager.shared.updateSubscriptionTier(tier)
                }
                self.onSuccess?()
                self.cleanup()
            }
        } else if url.host == "stripe-cancel" {
            safariViewController?.dismiss(animated: true) {
                self.onFailure?(StripeError.cancelled)
                self.cleanup()
            }
        }
    }
    
    private func cleanup() {
        safariViewController = nil
        onSuccess = nil
        onFailure = nil
        currentPlanID = nil
    }
}

extension StripePaymentHandler: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        onFailure?(StripeError.cancelled)
        cleanup()
    }
}

extension StripeError {
    static let invalidPriceId = StripeError.serverError("Invalid price ID")
    static let cancelled = StripeError.serverError("Payment cancelled")
}
