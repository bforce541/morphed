// morphed-ios/Morphed/Core/Utils/PhotoSaver.swift

import UIKit
import Photos

enum PhotoSaver {
    static func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }
    
    static func saveImage(_ image: UIImage) async throws {
        let authorized = await requestAuthorization()
        guard authorized else {
            throw PhotoSaveError.authorizationDenied
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

enum PhotoSaveError: LocalizedError {
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Photo library access was denied. Please enable it in Settings."
        }
    }
}

