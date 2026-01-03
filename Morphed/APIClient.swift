// APIClient.swift

import Foundation

enum APIClient {
    static func editImage(mode: String, imageBase64: String, mimeType: String) async throws -> EditResponse {
        let url = URL(string: "\(Constants.baseURL)/edit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.requestTimeout
        
        let body = EditRequest(mode: mode, imageBase64: imageBase64, mimeType: mimeType)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(EditResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .serverError(let message):
            return message
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

