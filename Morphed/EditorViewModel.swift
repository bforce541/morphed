// EditorViewModel.swift

import SwiftUI
import UIKit

@MainActor
class EditorViewModel: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var editedImage: UIImage?
    @Published var selectedMode: EditMode = .clean
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSaveSuccess = false
    
    enum EditMode: String, CaseIterable {
        case max = "max"
        case clean = "clean"
        
        var displayName: String {
            switch self {
            case .max: return "MAX"
            case .clean: return "CLEAN"
            }
        }
    }
    
    func morphImage() async {
        guard let originalImage = originalImage else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let resizedImage = ImageUtils.resizeImage(originalImage, maxDimension: Constants.maxImageDimension) ?? originalImage
            guard let jpegData = ImageUtils.compressToJPEG(resizedImage, quality: Constants.jpegCompressionQuality) else {
                throw APIError.networkError("Failed to compress image")
            }
            
            let base64String = ImageUtils.base64Encode(jpegData)
            
            let response = try await APIClient.editImage(
                mode: selectedMode.rawValue,
                imageBase64: base64String,
                mimeType: "image/jpeg"
            )
            
            guard let responseData = ImageUtils.decodeBase64(response.editedImageBase64),
                  let image = ImageUtils.imageFromData(responseData) else {
                throw APIError.decodingError("Failed to decode edited image")
            }
            
            editedImage = image
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func saveToPhotos() async {
        guard let editedImage = editedImage else { return }
        
        do {
            try await PhotoSaver.saveImage(editedImage)
            showSaveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

