// morphed-ios/Morphed/Features/Editor/EditorViewModel.swift

import SwiftUI
import UIKit
import Combine
import CoreImage

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
    @Published var hasGeneratedPreview = false
    
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
    
    // MARK: - Stubbed Generation
    
    func startGenerationStub() async {
        guard let originalImage = originalImage,
              let selectedMode = selectedMode else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        
        // Create preview image with blur and watermark
        var previewImage = originalImage
        
        // Apply blur effect for preview
        if let blurred = applyBlur(to: originalImage) {
            previewImage = blurred
        }
        
        // Apply watermark for free users
        if FeatureGates.shouldApplyWatermark() {
            previewImage = WatermarkRenderer.addWatermark(to: previewImage)
        }
        
        editedImage = previewImage
        
        // Record usage
        UsageTracker.recordMorph(isMax: selectedMode == .max)
        SubscriptionManager.shared.recordMorph(isPremium: selectedMode == .max)
        
        Haptics.notification(type: .success)
        isLoading = false
        
        // Trigger post-generation preview after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hasGeneratedPreview = true
        }
    }
    
    // MARK: - Real Generation (for when Gemini is ready)
    
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
            hasGeneratedPreview = true
            
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
    
    // MARK: - Helper Methods
    
    private func applyBlur(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(8.0, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
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
    
    func removeWatermark() {
        guard let originalImage = originalImage else { return }
        // When premium is unlocked, show the original without watermark
        editedImage = originalImage
        hasGeneratedPreview = true
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
