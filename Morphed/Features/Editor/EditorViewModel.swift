// morphed-ios/Morphed/Features/Editor/EditorViewModel.swift

import SwiftUI
import UIKit
import Combine

@MainActor
class EditorViewModel: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var editedImage: UIImage?
    @Published var selectedMode: EditMode? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSaveSuccess = false
    @Published var showImagePicker = false
    @Published var toastMessage: String?
    @Published var showToast = false
    
    enum EditMode: String, CaseIterable, Codable {
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
        guard let originalImage = originalImage,
              let selectedMode = selectedMode else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let resizedImage = ImageUtils.resizeImage(originalImage, maxDimension: 1536) ?? originalImage
            guard let jpegData = ImageUtils.compressToJPEG(resizedImage, quality: 0.85) else {
                throw APIError.encodingFailed
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
            
            var finalImage = image
            // Apply watermark for free tier / non-premium users.
            if FeatureGates.shouldApplyWatermark() {
                finalImage = WatermarkRenderer.addWatermark(to: image)
            }
            
            editedImage = finalImage
            
            // Save to history
            let historyItem = HistoryItem(
                originalImage: originalImage,
                editedImage: finalImage,
                mode: selectedMode
            )
            saveToHistory(historyItem)
            
            Haptics.notification(type: .success)
            showToast(message: "Image morphed successfully!")
            
            // Record usage and monetization events
            UsageTracker.recordMorph(isMax: selectedMode == .max)
            SubscriptionManager.shared.recordMorph(isPremium: selectedMode == .max)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
        
        isLoading = false
    }
    
    func saveToPhotos() async {
        guard let editedImage = editedImage else { return }
        
        do {
            try await PhotoSaver.saveImage(editedImage)
            showSaveSuccess = true
            Haptics.notification(type: .success)
            showToast(message: "Saved to Photos!")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
    }
    
    private func saveToHistory(_ item: HistoryItem) {
        var items: [HistoryItem] = []
        if let data = UserDefaults.standard.data(forKey: "morphed_history"),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            items = decoded
        }
        items.insert(item, at: 0)
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "morphed_history")
        }
    }
}

