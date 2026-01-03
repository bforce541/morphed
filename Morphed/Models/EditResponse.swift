// Models/EditResponse.swift

import Foundation

struct EditResponse: Codable {
    let editedImageBase64: String
    let mimeType: String
}

struct ErrorResponse: Codable {
    let error: String
}

