// morphed-ios/Morphed/Core/Models/APIError.swift

import Foundation

enum APIError: LocalizedError {
    case invalidImage
    case encodingFailed
    case networkError(Int?, String)
    case decodingError(String)
    case serverError(String, code: String?)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image selected"
        case .encodingFailed:
            return "Failed to encode image"
        case .networkError(let statusCode, let message):
            if let statusCode = statusCode {
                return "Network error (\(statusCode)): \(message)"
            }
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .serverError(let message, _):
            return message
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

