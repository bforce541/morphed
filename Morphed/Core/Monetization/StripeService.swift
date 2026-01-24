// Morphed/Core/Monetization/StripeService.swift

import Foundation

struct StripeCheckoutSessionResponse: Codable {
    let url: String
}

enum StripeService {
    static func createCheckoutSession(priceId: String, userId: String) async throws -> StripeCheckoutSessionResponse {
        let baseURL = UserDefaults.standard.string(forKey: "morphed_base_url") ?? "http://localhost:3000"
        let url = URL(string: "\(baseURL)/stripe/create-checkout-session")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let body: [String: Any] = [
            "priceId": priceId,
            "userId": userId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StripeError.connectionError("Invalid server response")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(StripeErrorResponse.self, from: data) {
                    throw StripeError.serverError(errorResponse.error?.message ?? "Server error")
                }
                throw StripeError.networkError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(StripeCheckoutSessionResponse.self, from: data)
            } catch {
                throw StripeError.decodingError(error.localizedDescription)
            }
        } catch let error as StripeError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw StripeError.connectionError("No internet connection. Please check your network.")
            case .cannotConnectToHost, .cannotFindHost:
                throw StripeError.connectionError("Cannot connect to server. Make sure the backend is running at \(baseURL)")
            case .timedOut:
                throw StripeError.connectionError("Connection timed out. The server may be down.")
            default:
                throw StripeError.connectionError("Could not connect to the server: \(urlError.localizedDescription)")
            }
        } catch {
            throw StripeError.connectionError("Could not connect to the server: \(error.localizedDescription)")
        }
    }
}

enum StripeError: LocalizedError {
    case invalidResponse
    case networkError(Int?)
    case serverError(String)
    case decodingError(String)
    case connectionError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let code):
            return "Network error\(code != nil ? " (code: \(code!))" : "")"
        case .serverError(let message):
            return message
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .connectionError(let message):
            return message
        }
    }
}

struct StripeErrorResponse: Codable {
    let error: StripeErrorDetail?
}

struct StripeErrorDetail: Codable {
    let code: String?
    let message: String
}
