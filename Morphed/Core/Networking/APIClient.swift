// morphed-ios/Morphed/Core/Networking/APIClient.swift

import Foundation

enum APIClient {
    static func editImage(mode: String, imageBase64: String, mimeType: String) async throws -> EditResponse {
        let baseURL = UserDefaults.standard.string(forKey: "morphed_base_url") ?? "http://localhost:3000"
        let url = URL(string: "\(baseURL)/edit")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120.0
        
        let body = EditRequest(mode: mode, imageBase64: imageBase64, mimeType: mimeType)
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    if let error = errorResponse.error {
                        throw APIError.serverError(error.message, code: error.code)
                    }
                    throw APIError.serverError(errorResponse.errorString ?? "Unknown error", code: nil)
                }
                throw APIError.networkError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
            do {
                return try JSONDecoder().decode(EditResponse.self, from: data)
            } catch {
                throw APIError.decodingError(error.localizedDescription)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(nil, error.localizedDescription)
        }
    }
}

