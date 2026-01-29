// morphed-ios/Morphed/Core/Imaging/PresencePreprocessor.swift

import UIKit
import Vision
import ImageIO

struct PresencePrecheckResult {
    let isValid: Bool
    let blockingMessage: String?
    let warningMessages: [String]
    let debugInfo: String?
}

enum PresencePreprocessor {
    enum Profile {
        case strict
        case candid
    }

    struct Thresholds {
        let minFaceAreaFraction: CGFloat
        let maxFaceAreaFraction: CGFloat
        let faceEdgeInset: CGFloat
        let maxYawRadians: CGFloat
        let maxRollRadians: CGFloat
        let minBrightness: CGFloat
        let warnLaplacianVariance: CGFloat
        let hardLaplacianVariance: CGFloat
        let minShoulderConfidence: Float
    }

    private static func thresholds(for profile: Profile) -> Thresholds {
        switch profile {
        case .strict:
            return Thresholds(
                minFaceAreaFraction: 0.08,
                maxFaceAreaFraction: 0.35,
                faceEdgeInset: 0.02,
                maxYawRadians: 0.35,
                maxRollRadians: 0.35,
                minBrightness: 0.35,
                warnLaplacianVariance: 80,
                hardLaplacianVariance: 30,
                minShoulderConfidence: 0.30
            )
        case .candid:
            return Thresholds(
                minFaceAreaFraction: 0.04,
                maxFaceAreaFraction: 0.45,
                faceEdgeInset: 0.005,
                maxYawRadians: 0.60,
                maxRollRadians: 0.60,
                minBrightness: 0.25,
                warnLaplacianVariance: 40,
                hardLaplacianVariance: 15,
                minShoulderConfidence: 0.15
            )
        }
    }

    static func validate(image: UIImage, profile: Profile = .candid) async -> PresencePrecheckResult {
        await Task.detached(priority: .userInitiated) {
            let thresholds = thresholds(for: profile)
            var warnings: [String] = []

            guard let cgImage = image.cgImage else {
                return PresencePrecheckResult(isValid: false, blockingMessage: "We couldn't read this photo. Try a different image file.", warningMessages: [], debugInfo: "missing_cgimage")
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
                return PresencePrecheckResult(isValid: false, blockingMessage: "We couldn't analyze the photo. Try retaking it in good light.", warningMessages: [], debugInfo: "vision_error")
            }

            let faces = (faceRequest.results as? [VNFaceObservation]) ?? []
            if faces.isEmpty {
                return PresencePrecheckResult(isValid: false, blockingMessage: "No face detected. Face the camera and make sure your face is visible.", warningMessages: [], debugInfo: "no_face")
            }
            if faces.count > 1 {
                return PresencePrecheckResult(isValid: false, blockingMessage: "Only one person should be in the photo. Try a solo shot.", warningMessages: [], debugInfo: "multiple_faces")
            }

            let face = faces[0]
            let bbox = face.boundingBox
            let faceArea = bbox.width * bbox.height

            if faceArea < thresholds.minFaceAreaFraction {
                warnings.append("Try moving closer so your face is larger in frame for better results.")
            }
            if faceArea > thresholds.maxFaceAreaFraction {
                warnings.append("Try moving farther back so more of your upper body is visible for better results.")
            }

            if bbox.minX < thresholds.faceEdgeInset ||
                bbox.minY < thresholds.faceEdgeInset ||
                (bbox.maxX) > (1 - thresholds.faceEdgeInset) ||
                (bbox.maxY) > (1 - thresholds.faceEdgeInset) {
                warnings.append("Try keeping your full face in frame (don’t crop the forehead or chin) for better results.")
            }

            if let yaw = face.yaw?.doubleValue, abs(yaw) > Double(thresholds.maxYawRadians) {
                warnings.append("Try facing the camera more directly (don’t turn sideways) for better results.")
            }
            if let roll = face.roll?.doubleValue, abs(roll) > Double(thresholds.maxRollRadians) {
                warnings.append("Try keeping your head level (avoid tilting) for better results.")
            }

            if let poseObs = (poseRequest.results as? [VNHumanBodyPoseObservation])?.first {
                let points = try? poseObs.recognizedPoints(.all)
                let left = points?[.leftShoulder]
                let right = points?[.rightShoulder]
                let leftConfidence = left?.confidence ?? 0
                let rightConfidence = right?.confidence ?? 0
                if leftConfidence < thresholds.minShoulderConfidence ||
                    rightConfidence < thresholds.minShoulderConfidence {
                    warnings.append("Try to include your shoulders in frame for better results.")
                }
            } else {
                warnings.append("Try to include your upper torso in frame (head + shoulders) for better results.")
            }

            if let brightness = ImageQualityAnalyzer.averageLuminance(for: image),
               brightness < thresholds.minBrightness {
                warnings.append("Try adding more light so your face and shoulders are clearly visible for better results.")
            }

            if let variance = ImageQualityAnalyzer.laplacianVariance(for: image),
               variance < thresholds.hardLaplacianVariance {
                return PresencePrecheckResult(isValid: false, blockingMessage: "Photo is too blurry. Hold the camera steady and refocus.", warningMessages: [], debugInfo: "too_blurry_hard")
            } else if let variance = ImageQualityAnalyzer.laplacianVariance(for: image),
                      variance < thresholds.warnLaplacianVariance {
                warnings.append("Photo looks a bit soft—try to hold steady for a sharper shot for better results.")
            }

            return PresencePrecheckResult(isValid: true, blockingMessage: nil, warningMessages: warnings, debugInfo: "ok")
        }.value
    }
}
