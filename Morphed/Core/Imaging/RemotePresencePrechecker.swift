// morphed-ios/Morphed/Core/Imaging/RemotePresencePrechecker.swift

import Foundation
import UIKit

enum RemotePresencePrechecker {
    struct ResultPayload: Decodable {
        let pass: Bool
        let blockingMessage: String?
        let warnings: [String]?
        let debug: String?
    }

    static func check(image: UIImage, mode: String) async -> PresencePrecheckResult {
        let baseURL = UserDefaults.standard.string(forKey: "morphed_base_url") ?? "http://localhost:3000"
        guard let url = URL(string: "\(baseURL)/precheck") else {
            return PresencePrecheckResult(
                isValid: false,
                blockingMessage: "We couldn't analyze the photo right now. Please try again.",
                warningMessages: [],
                debugInfo: "remote_precheck_bad_url baseURL=\(baseURL)"
            )
        }
        guard let jpegData = prepareForRemote(image) else {
            return PresencePrecheckResult(
                isValid: false,
                blockingMessage: "We couldn't read this photo. Try a different image file.",
                warningMessages: [],
                debugInfo: "remote_precheck_prepare_failed"
            )
        }
        let base64 = jpegData.base64EncodedString()

        let payload = [
            "imageBase64": base64,
            "mimeType": "image/jpeg",
            "mode": mode
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return PresencePrecheckResult(
                isValid: false,
                blockingMessage: "We couldn't analyze the photo right now. Please try again.",
                warningMessages: [],
                debugInfo: "remote_precheck_encode_failed"
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return PresencePrecheckResult(
                    isValid: false,
                    blockingMessage: "We couldn't analyze the photo right now. Please try again.",
                    warningMessages: [],
                    debugInfo: "remote_precheck_no_http_response"
                )
            }
            guard (200...299).contains(http.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let detail = errorResponse.error?.message ?? errorResponse.errorString ?? "unknown_error"
                    return PresencePrecheckResult(
                        isValid: false,
                        blockingMessage: "We couldn't analyze the photo right now. Please try again.",
                        warningMessages: [],
                        debugInfo: "remote_precheck_http_\(http.statusCode) \(detail)"
                    )
                }
                let bodySnippet = String(data: data.prefix(200), encoding: .utf8) ?? "non_utf8_body"
                return PresencePrecheckResult(
                    isValid: false,
                    blockingMessage: "We couldn't analyze the photo right now. Please try again.",
                    warningMessages: [],
                    debugInfo: "remote_precheck_http_\(http.statusCode) body=\(bodySnippet)"
                )
            }

            guard let result = try? JSONDecoder().decode(ResultPayload.self, from: data) else {
                let bodySnippet = String(data: data.prefix(200), encoding: .utf8) ?? "non_utf8_body"
                return PresencePrecheckResult(
                    isValid: false,
                    blockingMessage: "We couldn't analyze the photo right now. Please try again.",
                    warningMessages: [],
                    debugInfo: "remote_precheck_decode_failed body=\(bodySnippet)"
                )
            }

            return PresencePrecheckResult(
                isValid: result.pass,
                blockingMessage: result.blockingMessage,
                warningMessages: result.warnings ?? [],
                debugInfo: result.debug
            )
        } catch {
            return PresencePrecheckResult(
                isValid: false,
                blockingMessage: "We couldn't analyze the photo right now. Please try again.",
                warningMessages: [],
                debugInfo: "remote_precheck_error:\(error.localizedDescription)"
            )
        }
    }

    private static func prepareForRemote(_ image: UIImage) -> Data? {
        guard let normalized = ImageUtils.normalizeOrientation(image) else { return nil }
        let resized = ImageUtils.resizeImage(normalized, maxDimension: 1024, preserveScale: false) ?? normalized
        return ImageUtils.compressToJPEG(resized, quality: 0.75)
    }

}
