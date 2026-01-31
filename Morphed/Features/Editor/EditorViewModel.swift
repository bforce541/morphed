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
    @Published var didSaveToHistory = false
    @Published var didUploadToSupabase = false
    @Published var isPreviewBlurred = false
    @Published var precheckDebugInfo: String?
    @Published var warningMessage: String?
    @Published var showWarningPrompt = false

    private var warningContinuation: CheckedContinuation<Bool, Never>?
    
    enum EditMode: String, CaseIterable, Codable {
        case presence = "presence"
        case physique = "physique"
        case face = "face"
        case professionality = "professionality"
        
        var displayName: String {
            switch self {
            case .presence: return "Presence"
            case .physique: return "Physique"
            case .face: return "Face"
            case .professionality: return "Professionality"
            }
        }
        
        var shortDescription: String {
            switch self {
            case .presence: return "Optimized posture, proportions, and framing"
            case .physique: return "Visual definition through lighting, shadows, and fit"
            case .face: return "Structure & clarity enhancement"
            case .professionality: return "Polished, professional presentation"
            }
        }
        
        var bulletPoints: [String] {
            switch self {
            case .presence: return [
                "Upright posture",
                "Camera angle correction",
                "Shoulder framing",
                "Subtle vertical elongation (optical, not literal)"
            ]
            case .physique: return [
                "V-taper emphasis",
                "Chest/shoulder lighting",
                "Shirt tightening (wrinkles → structure)",
                "No fake muscles"
            ]
            case .face: return [
                "Jaw/cheekbone definition",
                "Eye clarity",
                "Skin texture polish"
            ]
            case .professionality: return [
                "Polished appearance",
                "Cleaner lines",
                "Subtle contrast refinement"
            ]
            }
        }
        
        var icon: String {
            switch self {
            case .presence: return "figure.stand"
            case .physique: return "dumbbell"
            case .face: return "face.smiling"
            case .professionality: return "briefcase"
            }
        }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            switch s {
            case "presence": self = .presence
            case "physique": self = .physique
            case "face": self = .face
            case "style": self = .professionality
            case "professionality": self = .professionality
            case "max": self = .presence
            case "clean": self = .professionality
            default: self = .presence
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            try c.encode(rawValue)
        }
    }

    private func requiresPresencePrecheck(for mode: EditMode) -> Bool {
        mode == .presence || mode == .face || mode == .professionality
    }
    
    // MARK: - Stubbed Generation
    
    func startGenerationStub() async {
        guard let originalImage = originalImage,
              let selectedMode = selectedMode else { return }
        
        isLoading = true
        errorMessage = nil
        precheckDebugInfo = nil
        didSaveToHistory = false
        didUploadToSupabase = false
        isPreviewBlurred = false

        if requiresPresencePrecheck(for: selectedMode) {
            let precheck = await PresencePreprocessor.validate(image: originalImage, profile: .candid)
            if !precheck.isValid {
                precheckDebugInfo = precheck.debugInfo
                errorMessage = precheck.blockingMessage ?? "Please try another photo."
                showError = true
                Haptics.notification(type: .error)
                isLoading = false
                return
            }
            if let warning = precheck.warningMessages.first {
                isLoading = false
                let proceed = await awaitWarningDecision(message: warning)
                if !proceed {
                    return
                }
                isLoading = true
            }
        }
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        
        // Create preview image with blur and watermark
        var previewImage = originalImage
        
        let shouldBlurPreview = FeatureGates.shouldApplyWatermark()
        if shouldBlurPreview, let blurred = applyBlur(to: originalImage, radius: previewBlurRadius(for: selectedMode)) {
            previewImage = blurred
            isPreviewBlurred = true
        }
        
        // Apply watermark for free users
        if FeatureGates.shouldApplyWatermark() {
            previewImage = WatermarkRenderer.addWatermark(to: previewImage)
        }
        
        editedImage = previewImage
        hasGeneratedPreview = true
        
        // Save to history immediately (even for stub)
        let historyItem = HistoryItem(
            originalImage: originalImage,
            editedImage: previewImage,
            mode: selectedMode
        )
        saveToHistory(historyItem)
        didSaveToHistory = true
        
        // Upload to Supabase in background
        Task { [originalImage, previewImage, selectedMode, historyId = historyItem.id] in
            await uploadToSupabase(
                original: originalImage,
                created: previewImage,
                mode: selectedMode,
                historyId: historyId
            )
        }
        
        // Record usage
        UsageTracker.recordMorph(mode: selectedMode)
        SubscriptionManager.shared.recordMorph(isPremium: selectedMode != .presence, triggerPaywall: false)
        
        Haptics.notification(type: .success)
        isLoading = false
    }
    
    // MARK: - Real Generation (for when Gemini is ready)
    
    func morphImage() async {
        guard let originalImage = originalImage,
              let selectedMode = selectedMode else { return }
        
        isLoading = true
        errorMessage = nil
        precheckDebugInfo = nil
        didSaveToHistory = false
        isPreviewBlurred = false
        
        do {
            if requiresPresencePrecheck(for: selectedMode) {
                let precheck = await PresencePreprocessor.validate(image: originalImage, profile: .candid)
                if !precheck.isValid {
                    precheckDebugInfo = precheck.debugInfo
                    errorMessage = precheck.blockingMessage ?? "Please try another photo."
                    showError = true
                    Haptics.notification(type: .error)
                    isLoading = false
                    return
                }
                if let warning = precheck.warningMessages.first {
                    isLoading = false
                    let proceed = await awaitWarningDecision(message: warning)
                    if !proceed {
                        return
                    }
                    isLoading = true
                }
            }

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
            if selectedMode == .presence, let faceLocked = FaceLockComposer.apply(original: originalImage, edited: image) {
                finalImage = faceLocked
            }
            // Apply watermark for free tier / non-premium users.
            if FeatureGates.shouldApplyWatermark() {
                finalImage = WatermarkRenderer.addWatermark(to: finalImage)
            }
            
            editedImage = finalImage
            hasGeneratedPreview = true
            isPreviewBlurred = false
            
            // Save to history
            let historyItem = HistoryItem(
                originalImage: originalImage,
                editedImage: finalImage,
                mode: selectedMode
            )
            saveToHistory(historyItem)
            didSaveToHistory = true

            Task { [originalImage, finalImage, selectedMode, historyId = historyItem.id] in
                await uploadToSupabase(
                    original: originalImage,
                    created: finalImage,
                    mode: selectedMode,
                    historyId: historyId
                )
            }
            
            Haptics.notification(type: .success)
            showToast(message: "Image morphed successfully!")
            
            // Record usage and monetization events
            UsageTracker.recordMorph(mode: selectedMode)
            SubscriptionManager.shared.recordMorph(isPremium: selectedMode != .presence, triggerPaywall: false)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.notification(type: .error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func previewBlurRadius(for mode: EditMode) -> CGFloat { 9 }
    
    private func applyBlur(to image: UIImage, radius: CGFloat) -> UIImage? {
        guard let baseCIImage = CIImage(image: image) else { return nil }
        let ciImage = baseCIImage.oriented(forExifOrientation: image.exifOrientation)
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
    
    func saveToPhotos() async {
        guard let editedImage = editedImage else { return }
        
        do {
            var imageToSave = editedImage
            if FeatureGates.shouldApplyWatermark(),
               !isPreviewBlurred,
               let selectedMode = selectedMode,
               let blurred = applyBlur(to: editedImage, radius: previewBlurRadius(for: selectedMode)) {
                imageToSave = blurred
            }
            
            try await PhotoSaver.saveImage(imageToSave)
            if !didSaveToHistory, let selectedMode = selectedMode {
                let historyItem = HistoryItem(
                    originalImage: originalImage,
                    editedImage: imageToSave,
                    mode: selectedMode
                )
                saveToHistory(historyItem)
                didSaveToHistory = true
                if let originalImage = originalImage {
                    Task { [originalImage, imageToSave, selectedMode, historyId = historyItem.id] in
                        await uploadToSupabase(
                            original: originalImage,
                            created: imageToSave,
                            mode: selectedMode,
                            historyId: historyId
                        )
                    }
                }
            }
            showSaveSuccess = true
            Haptics.notification(type: .success)
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
    
    func clearSelectedImage() {
        originalImage = nil
        editedImage = nil
        selectedMode = nil
        hasGeneratedPreview = false
        didSaveToHistory = false
        didUploadToSupabase = false
        isPreviewBlurred = false
        warningMessage = nil
        showWarningPrompt = false
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
    }

    func resolveWarningDecision(proceed: Bool) {
        showWarningPrompt = false
        let continuation = warningContinuation
        warningContinuation = nil
        continuation?.resume(returning: proceed)
    }

    private func awaitWarningDecision(message: String) async -> Bool {
        warningMessage = message
        showWarningPrompt = true
        return await withCheckedContinuation { continuation in
            warningContinuation = continuation
        }
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
            // Notify HistoryViewModel to reload
            NotificationCenter.default.post(name: NSNotification.Name("HistoryDidUpdate"), object: nil)
        }
    }

    private func uploadToSupabase(
        original: UIImage,
        created: UIImage,
        mode: EditMode,
        historyId: String
    ) async {
        do {
            let finalPairId = try await AuthManager.shared.storeCreatedImagePair(
                original: original,
                created: created,
                mode: mode.rawValue,
                pairId: historyId
            )
            didUploadToSupabase = true
            markHistoryItemSynced(id: historyId, pairId: finalPairId)
        } catch {
            // Best-effort upload; failures shouldn't block the user flow.
        }
    }

    private func markHistoryItemSynced(id: String, pairId: String) {
        guard let data = UserDefaults.standard.data(forKey: "morphed_history"),
              var items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return
        }

        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isSynced = true
            items[index].pairId = pairId
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "morphed_history")
            }
        }
    }
}
