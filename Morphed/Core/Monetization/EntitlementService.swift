// Morphed/Core/Monetization/EntitlementService.swift
// Fetches entitlements from backend (source of truth). Used after IAP verify and on app launch.

import Foundation

struct EntitlementResponse: Codable {
    let tier: String
    let canUseMaxMode: Bool?
    let canExportHD: Bool?
    let remainingPremiumRenders: Int?
    let isPro: Bool?
    let expiresAt: Int?
}

enum EntitlementServiceError: LocalizedError {
    case noUserId
    case networkError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noUserId: return "User not signed in"
        case .networkError(let msg): return msg
        case .invalidResponse: return "Invalid server response"
        }
    }
}

enum EntitlementService {
    private static var baseURL: String {
        UserDefaults.standard.string(forKey: "morphed_base_url") ?? "http://localhost:3000"
    }

    /// GET /entitlements?user_id=xxx — backend is source of truth.
    static func fetchEntitlements(userId: String) async throws -> EntitlementResponse {
        guard !userId.isEmpty else { throw EntitlementServiceError.noUserId }
        var components = URLComponents(string: "\(baseURL)/entitlements")!
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        guard let url = components.url else { throw EntitlementServiceError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw EntitlementServiceError.networkError("Failed to fetch entitlements")
        }
        let decoded = try JSONDecoder().decode(EntitlementResponse.self, from: data)
        #if DEBUG
        print("[EntitlementService] GET /entitlements success tier=\(decoded.tier)")
        #endif
        return decoded
    }

    /// POST /iap/apple/verify — verify JWS and update backend entitlements.
    static func verifyAppleTransaction(
        userId: String,
        signedTransactionInfo: String,
        environment: String
    ) async throws -> EntitlementResponse {
        guard !userId.isEmpty else { throw EntitlementServiceError.noUserId }
        let url = URL(string: "\(baseURL)/iap/apple/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let body: [String: Any] = [
            "user_id": userId,
            "signed_transaction_info": signedTransactionInfo,
            "environment": environment
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw EntitlementServiceError.invalidResponse }
        if !(200...299).contains(http.statusCode) {
            #if DEBUG
            print("[EntitlementService] POST /iap/apple/verify failed HTTP \(http.statusCode)")
            #endif
            if let err = try? JSONDecoder().decode(ServerError.self, from: data) {
                throw EntitlementServiceError.networkError(err.error?.message ?? "Verification failed")
            }
            throw EntitlementServiceError.networkError("Verification failed (HTTP \(http.statusCode))")
        }
        let decoded = try JSONDecoder().decode(EntitlementResponse.self, from: data)
        #if DEBUG
        print("[EntitlementService] POST /iap/apple/verify success tier=\(decoded.tier)")
        #endif
        return decoded
    }
}

private struct ServerError: Codable {
    let error: ServerErrorDetail?
}
private struct ServerErrorDetail: Codable {
    let message: String?
}
