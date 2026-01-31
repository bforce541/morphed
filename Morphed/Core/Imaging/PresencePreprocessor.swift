// morphed-ios/Morphed/Core/Imaging/PresencePreprocessor.swift

import UIKit

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

        // Applied to an expanded face bbox (less twitchy than tiny insets)
        let faceEdgeMargin: CGFloat
        let faceBBoxExpand: CGFloat

        let maxYawRadians: CGFloat
        let maxRollRadians: CGFloat

        // Measured on the face crop (reduces false “too dark”)
        let minFaceBrightness: CGFloat

        let warnLaplacianVariance: CGFloat
        let hardLaplacianVariance: CGFloat

        // Pose thresholds
        let minShoulderConfidence: Float
        let minNeckConfidence: Float

        // Shoulder warning behavior
        let requireUpperBodyInStrict: Bool
        let shoulderCheckFaceAreaTrigger: CGFloat
    }

    private static func thresholds(for profile: Profile) -> Thresholds {
        switch profile {
        case .strict:
            return Thresholds(
                minFaceAreaFraction: 0.06,
                maxFaceAreaFraction: 0.45,
                faceEdgeMargin: 0.04,
                faceBBoxExpand: 0.06,
                maxYawRadians: 0.45,
                maxRollRadians: 0.45,
                minFaceBrightness: 0.30,
                warnLaplacianVariance: 70,
                hardLaplacianVariance: 22,
                minShoulderConfidence: 0.20,
                minNeckConfidence: 0.20,
                requireUpperBodyInStrict: true,
                shoulderCheckFaceAreaTrigger: 0.18
            )
        case .candid:
            return Thresholds(
                minFaceAreaFraction: 0.03,
                maxFaceAreaFraction: 0.55,
                faceEdgeMargin: 0.02,
                faceBBoxExpand: 0.06,
                maxYawRadians: 0.70,
                maxRollRadians: 0.70,
                minFaceBrightness: 0.22,
                warnLaplacianVariance: 35,
                hardLaplacianVariance: 12,
                minShoulderConfidence: 0.12,
                minNeckConfidence: 0.12,
                requireUpperBodyInStrict: false,
                shoulderCheckFaceAreaTrigger: 0.22
            )
        }
    }

    /// Main entry point
    static func validate(image: UIImage, profile: Profile = .candid) async -> PresencePrecheckResult {
        await Task.detached(priority: .userInitiated) {
            await RemotePresencePrechecker.check(image: image)
        }.value
    }
}
