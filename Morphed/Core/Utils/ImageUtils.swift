// morphed-ios/Morphed/Core/Utils/ImageUtils.swift

import UIKit

enum ImageUtils {
    private static let portraitAspect: CGFloat = 9.0 / 16.0
    private static let landscapeAspect: CGFloat = 16.0 / 9.0

    /// Aspect-fit resize to a max dimension. Uses UIGraphicsImageRenderer for better quality.
    /// Preserves the original image scale by default.
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat, preserveScale: Bool = true) -> UIImage? {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > 0 else { return nil }

        let ratio = maxDimension / maxSide
        guard ratio < 1.0 else { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return resizeImage(image, targetSize: newSize, scale: preserveScale ? image.scale : 1.0)
    }

    /// Resize to an explicit target size. Uses UIGraphicsImageRenderer.
    /// If you want deterministic pixel behavior for analysis, pass scale = 1.
    static func resizeImage(_ image: UIImage, targetSize: CGSize, scale: CGFloat? = nil) -> UIImage? {
        let renderScale = scale ?? image.scale

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = renderScale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Normalize UIImage orientation so cgImage + Vision see what the user sees.
    static func normalizeOrientation(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up {
            return image
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false

        let targetSize: CGSize = {
            if let cgImage = image.cgImage {
                let baseSize = CGSize(
                    width: CGFloat(cgImage.width) / image.scale,
                    height: CGFloat(cgImage.height) / image.scale
                )
                switch image.imageOrientation {
                case .left, .leftMirrored, .right, .rightMirrored:
                    return CGSize(width: baseSize.height, height: baseSize.width)
                default:
                    return baseSize
                }
            } else {
                switch image.imageOrientation {
                case .left, .leftMirrored, .right, .rightMirrored:
                    return CGSize(width: image.size.height, height: image.size.width)
                default:
                    return image.size
                }
            }
        }()

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    static func compressToJPEG(_ image: UIImage, quality: CGFloat) -> Data? {
        image.jpegData(compressionQuality: quality)
    }

    static func base64Encode(_ data: Data) -> String {
        data.base64EncodedString()
    }

    static func decodeBase64(_ base64String: String) -> Data? {
        Data(base64Encoded: base64String)
    }

    static func imageFromData(_ data: Data) -> UIImage? {
        UIImage(data: data)
    }

    /// Center-crop an image to the given aspect ratio.
    static func cropToAspect(_ image: UIImage, aspectRatio: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage, aspectRatio > 0 else { return nil }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let currentAspect = width / height

        var cropRect: CGRect
        if currentAspect > aspectRatio {
            let newWidth = height * aspectRatio
            let x = (width - newWidth) * 0.5
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: height)
        } else {
            let newHeight = width / aspectRatio
            let y = (height - newHeight) * 0.5
            cropRect = CGRect(x: 0, y: y, width: width, height: newHeight)
        }

        guard let cropped = cgImage.cropping(to: cropRect.integral) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }

    /// Convenience square crop (centered).
    static func cropToSquare(_ image: UIImage) -> UIImage? {
        cropToAspect(image, aspectRatio: 1.0)
    }

    /// Choose 9:16 or 16:9 based on which is closer to the source aspect.
    static func closestStandardAspect(for image: UIImage) -> CGFloat {
        guard let cgImage = image.cgImage else {
            let fallback = image.size.width / max(1, image.size.height)
            return closestStandardAspect(for: fallback)
        }
        let current = CGFloat(cgImage.width) / max(1, CGFloat(cgImage.height))
        return closestStandardAspect(for: current)
    }

    private static func closestStandardAspect(for aspect: CGFloat) -> CGFloat {
        let dPortrait = abs(aspect - portraitAspect)
        let dLandscape = abs(aspect - landscapeAspect)
        return dPortrait <= dLandscape ? portraitAspect : landscapeAspect
    }
}
