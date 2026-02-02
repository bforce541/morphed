// Morphed/Core/Monetization/IAPManager.swift
// StoreKit 2 subscription purchase, restore, and transaction updates.
// Does NOT gate features — backend entitlement is the source of truth.

import Foundation
import Combine
import StoreKit

/// Verified transaction payload to send to backend for entitlement update.
struct VerifiedTransactionPayload {
    let productId: String
    let transactionId: UInt64
    let originalTransactionId: UInt64
    let jwsRepresentation: String
    let environment: String // "Production" or "Sandbox"
}

/// Purchase / restore outcome for UI.
enum IAPPurchaseResult {
    case success(VerifiedTransactionPayload)
    case userCancelled
    case pending  // e.g. Ask to Buy
    case failed(Error)
}

/// Restore outcome.
enum IAPRestoreResult {
    case success
    case noPurchasesToRestore
    case failed(Error)
}

enum IAPError: LocalizedError {
    case productNotAvailable
    case verificationFailed
    case unknownResult

    var errorDescription: String? {
        switch self {
        case .productNotAvailable: return "Product not available"
        case .verificationFailed: return "Verification failed"
        case .unknownResult: return "Unknown error"
        }
    }
}

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var loadError: Error?
    @Published private(set) var purchaseState: PurchaseState = .idle

    enum PurchaseState {
        case idle
        case purchasing
        case restoring
        case verifying
    }

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactionUpdates()
        // Verify product ID mapping is correct (prevents regressions)
        IAPProductID.verifyMapping()
        Task { await loadProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product loading

    func loadProducts() async {
        isLoadingProducts = true
        loadError = nil
        defer { isLoadingProducts = false }
        do {
            let ids = IAPProductID.subscriptionIDs
            products = try await Product.products(for: ids).sorted { $0.price < $1.price }
            loadError = nil
            log("IAP", "Loaded \(products.count) products: \(products.map(\.id))")
            // TODO: Validate on real device with Sandbox; product IDs must match App Store Connect.
        } catch {
            loadError = error
            products = []
            log("IAP", "Load products failed: \(error.localizedDescription)")
        }
    }

    /// Get StoreKit Product for plan (for display price).
    func product(for planID: PricingPlanID) -> Product? {
        guard let iapID = IAPProductID.productID(for: planID) else { return nil }
        return products.first { $0.id == iapID.rawValue }
    }

    /// Localized price string for a plan (e.g. "$6.99 / month").
    func priceString(for planID: PricingPlanID) -> String? {
        product(for: planID).map { $0.displayPrice }
    }

    // MARK: - Purchase

    func purchase(productID: IAPProductID) async -> IAPPurchaseResult {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            log("IAP", "Purchase failed: product not loaded \(productID.rawValue)")
            return .failed(IAPError.productNotAvailable)
        }

        purchaseState = .purchasing
        log("IAP", "Purchase started: \(productID.rawValue)")
        defer { purchaseState = .idle }
        // TODO: Test full purchase flow on real device (Sandbox) and confirm backend verify.

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    let jws = verification.jwsRepresentation
                    if let payload = makePayload(transaction: transaction, jwsRepresentation: jws) {
                        await transaction.finish()
                        log("IAP", "Purchase success: \(productID.rawValue) tx=\(transaction.id)")
                        return .success(payload)
                    }
                    return .failed(IAPError.verificationFailed)
                case .unverified(_, let error):
                    log("IAP", "Purchase unverified: \(error.localizedDescription)")
                    return .failed(IAPError.verificationFailed)
                }
            case .userCancelled:
                log("IAP", "Purchase cancelled by user")
                return .userCancelled
            case .pending:
                log("IAP", "Purchase pending (e.g. Ask to Buy)")
                return .pending
            @unknown default:
                return .failed(IAPError.unknownResult)
            }
        } catch {
            log("IAP", "Purchase failed: \(error.localizedDescription)")
            return .failed(error)
        }
    }

    // MARK: - Restore

    func restorePurchases() async -> IAPRestoreResult {
        purchaseState = .restoring
        log("IAP", "Restore started")
        defer { purchaseState = .idle }

        do {
            try await AppStore.sync()
            var hadAny = false
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    hadAny = true
                    await transaction.finish()
                    log("IAP", "Restore: found entitlement \(transaction.productID) tx=\(transaction.id)")
                }
            }
            log("IAP", "Restore finished, hadEntitlements=\(hadAny)")
            return hadAny ? .success : .noPurchasesToRestore
        } catch {
            log("IAP", "Restore failed: \(error.localizedDescription)")
            return .failed(error)
        }
    }

    /// Call after restore when you have the latest transaction to verify with backend.
    /// Returns a payload for the "best" current entitlement (e.g. for verification).
    func currentEntitlementPayload() async -> VerifiedTransactionPayload? {
        let all = await allCurrentEntitlementPayloads()
        return all.first
    }

    /// All current entitlement payloads (for restore: verify each on backend).
    func allCurrentEntitlementPayloads() async -> [VerifiedTransactionPayload] {
        var payloads: [VerifiedTransactionPayload] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                let jws = result.jwsRepresentation
                if let payload = makePayload(transaction: transaction, jwsRepresentation: jws) {
                    payloads.append(payload)
                }
            }
        }
        return payloads
    }

    // MARK: - Transaction updates (e.g. renewals, family sharing)

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    log("IAP", "Transaction update: \(transaction.productID) tx=\(transaction.id)")
                }
            }
        }
    }

    // MARK: - Helpers

    private var currentEnvironment: String {
        #if DEBUG
        return "Sandbox"
        #else
        return "Production"
        #endif
    }

    private func makePayload(transaction: Transaction, jwsRepresentation jws: String) -> VerifiedTransactionPayload? {
        guard !jws.isEmpty else { return nil }
        return VerifiedTransactionPayload(
            productId: transaction.productID,
            transactionId: transaction.id,
            originalTransactionId: transaction.originalID,
            jwsRepresentation: jws,
            environment: currentEnvironment
        )
    }

    #if DEBUG
    private func log(_ tag: String, _ message: String) {
        print("[\(tag)] \(message)")
    }
    #else
    private func log(_ tag: String, _ message: String) {}
    #endif
}
