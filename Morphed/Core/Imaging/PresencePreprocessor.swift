// morphed-ios/Morphed/Core/Imaging/PresencePreprocessor.swift

import UIKit
import Vision
import ImageIO

struct PresencePrecheckResult {
    let isValid: Bool
    let userMessage: String?
    let debugInfo: String?
}

enum PresencePreprocessor {
    struct Thresholds {
        let minFaceAreaFraction: CGFloat = 0.08
        let maxFaceAreaFraction: CGFloat = 0.35
        let faceEdgeInset: CGFloat = 0.02
        let maxYawRadians: CGFloat = 0.35
        let maxRollRadians: CGFloat = 0.35
        let minBrightness: CGFloat = 0.35
        let minLaplacianVariance: CGFloat = 80
        let minShoulderConfidence: Float = 0.3
    }

    static func validate(image: UIImage, thresholds: Thresholds = Thresholds()) async -> PresencePrecheckResult {
        await Task.detached(priority: .userInitiated) {
            guard let cgImage = image.cgImage else {
                return PresencePrecheckResult(isValid: false, userMessage: "We couldn't read this photo. Try a different image file.", debugInfo: "missing_cgimage")
            }

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: CGImagePropertyOrientation(rawValue: UInt32(image.exifOrientation)) ?? .up,
                options: [:]
            )

            let faceRequest = VNDetectFaceRectanglesRequest()
            let poseRequest = VNDetectHumanBodyPoseRequest()

            do {
                try handler.perform([faceRequest, poseRequest])
            } catch {
                return PresencePrecheckResult(isValid: false, userMessage: "We couldn't analyze the photo. Try retaking it in good light.", debugInfo: "vision_error")
            }

            let faces = (faceRequest.results as? [VNFaceObservation]) ?? []
            if faces.isEmpty {
                return PresencePrecheckResult(isValid: false, userMessage: "No face detected. Face the camera and make sure your face is visible.", debugInfo: "no_face")
            }
            if faces.count > 1 {
                return PresencePrecheckResult(isValid: false, userMessage: "Only one person should be in the photo. Try a solo shot.", debugInfo: "multiple_faces")
            }

            let face = faces[0]
            let bbox = face.boundingBox
            let faceArea = bbox.width * bbox.height

            if faceArea < thresholds.minFaceAreaFraction {
                return PresencePrecheckResult(isValid: false, userMessage: "Move closer to the camera so your face is larger in frame.", debugInfo: "face_too_small")
            }
            if faceArea > thresholds.maxFaceAreaFraction {
                return PresencePrecheckResult(isValid: false, userMessage: "Move farther back so more of your upper body is visible.", debugInfo: "face_too_large")
            }

            if bbox.minX < thresholds.faceEdgeInset ||
                bbox.minY < thresholds.faceEdgeInset ||
                (bbox.maxX) > (1 - thresholds.faceEdgeInset) ||
                (bbox.maxY) > (1 - thresholds.faceEdgeInset) {
                return PresencePrecheckResult(isValid: false, userMessage: "Keep your full face in frame (don’t crop the forehead or chin).", debugInfo: "face_clipped")
            }

            if let yaw = face.yaw?.doubleValue, abs(yaw) > Double(thresholds.maxYawRadians) {
                return PresencePrecheckResult(isValid: false, userMessage: "Face the camera directly (don’t turn sideways).", debugInfo: "yaw_exceeded")
            }
            if let roll = face.roll?.doubleValue, abs(roll) > Double(thresholds.maxRollRadians) {
                return PresencePrecheckResult(isValid: false, userMessage: "Keep your head level (avoid tilting).", debugInfo: "roll_exceeded")
            }

            if let poseObs = (poseRequest.results as? [VNHumanBodyPoseObservation])?.first {
                let points = try? poseObs.recognizedPoints(.all)
                let left = points?[.leftShoulder]
                let right = points?[.rightShoulder]
                if left?.confidence ?? 0 < thresholds.minShoulderConfidence ||
                    right?.confidence ?? 0 < thresholds.minShoulderConfidence {
                    return PresencePrecheckResult(isValid: false, userMessage: "Include both shoulders in the frame.", debugInfo: "shoulders_missing")
                }
            } else {
                return PresencePrecheckResult(isValid: false, userMessage: "Include your upper torso in the frame (head + shoulders).", debugInfo: "no_pose")
            }

            if let brightness = ImageQualityAnalyzer.averageLuminance(for: image),
               brightness < thresholds.minBrightness {
                return PresencePrecheckResult(isValid: false, userMessage: "Add more light so your face and shoulders are clearly visible.", debugInfo: "low_brightness")
            }

            if let variance = ImageQualityAnalyzer.laplacianVariance(for: image),
               variance < thresholds.minLaplacianVariance {
                return PresencePrecheckResult(isValid: false, userMessage: "Photo is too blurry. Hold the camera steady and refocus.", debugInfo: "too_blurry")
            }

            return PresencePrecheckResult(isValid: true, userMessage: nil, debugInfo: "ok")
        }.value
    }
}
