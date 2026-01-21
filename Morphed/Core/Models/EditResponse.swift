// morphed-ios/Morphed/Core/Models/EditResponse.swift

import Foundation

struct EditResponse: Codable {
    let editedImageBase64: String
    let mimeType: String
}

struct ErrorResponse: Codable {
    let error: ErrorDetail?
    let errorString: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let errorDetail = try? container.decode(ErrorDetail.self, forKey: .error) {
            self.error = errorDetail
            self.errorString = nil
        } else if let errorString = try? container.decode(String.self, forKey: .error) {
            self.error = nil
            self.errorString = errorString
        } else {
            self.error = nil
            self.errorString = "Unknown error"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case error
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let error = error {
            try container.encode(error, forKey: .error)
        } else if let errorString = errorString {
            try container.encode(errorString, forKey: .error)
        }
    }
}

struct ErrorDetail: Codable {
    let code: String
    let message: String
    let details: String?
}

