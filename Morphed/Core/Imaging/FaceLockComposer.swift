// morphed-ios/Morphed/Core/Imaging/FaceLockComposer.swift

import UIKit
import Vision
import CoreImage
import ImageIO

struct FaceLockConfig {
    let padding: CGFloat = 18
    let feather: CGFloat = 10
}

enum FaceLockComposer {
    static func apply(original: UIImage, edited: UIImage, config: FaceLockConfig = FaceLockConfig()) -> UIImage? {
        guard let resizedEdited = resizeIfNeeded(edited, toMatch: original) else { return nil }
        guard let mask = FaceMaskGenerator.generateMask(from: original, config: config) else {
            return resizedEdited
        }

        guard let originalCI = CIImage(image: original)?.oriented(forExifOrientation: original.exifOrientation),
              let editedCI = CIImage(image: resizedEdited)?.oriented(forExifOrientation: resizedEdited.exifOrientation) else {
            return resizedEdited
        }

        let filter = CIFilter(name: "CIBlendWithMask")
        filter?.setValue(originalCI, forKey: kCIInputImageKey)
        filter?.setValue(editedCI, forKey: kCIInputBackgroundImageKey)
        filter?.setValue(mask, forKey: kCIInputMaskImageKey)
        guard let output = filter?.outputImage else { return resizedEdited }

        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return resizedEdited }
        return UIImage(cgImage: cgImage, scale: original.scale, orientation: .up)
    }

    private static func resizeIfNeeded(_ edited: UIImage, toMatch original: UIImage) -> UIImage? {
        let targetSize = original.size
        if edited.size == targetSize {
            return edited
        }
        return ImageUtils.resizeImage(edited, targetSize: targetSize) ?? edited
    }
}

enum FaceMaskGenerator {
    // TODO: Replace Vision rectangle mask with MediaPipe Face Mesh polygon mask.
    static func generateMask(from image: UIImage, config: FaceLockConfig) -> CIImage? {
        guard let ciImage = CIImage(image: image)?.oriented(forExifOrientation: image.exifOrientation) else {
            return nil
        }
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: .up,
            options: [:]
        )
        let request = VNDetectFaceRectanglesRequest()
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let face = (request.results as? [VNFaceObservation])?.first else {
            return nil
        }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let rect = face.boundingBox
        let faceRect = VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height))

        let paddedRect = faceRect.insetBy(dx: -config.padding, dy: -config.padding)
        let clamped = paddedRect.intersection(CGRect(origin: .zero, size: imageSize))

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))

        context.setFillColor(UIColor.white.cgColor)
        let cornerRadius = min(clamped.width, clamped.height) * 0.2
        let path = UIBezierPath(roundedRect: clamped, cornerRadius: cornerRadius)
        context.addPath(path.cgPath)
        context.fillPath()

        guard let maskImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        guard var maskCI = CIImage(image: maskImage) else { return nil }
        if let blur = CIFilter(name: "CIGaussianBlur") {
            blur.setValue(maskCI, forKey: kCIInputImageKey)
            blur.setValue(config.feather, forKey: kCIInputRadiusKey)
            if let blurred = blur.outputImage {
                maskCI = blurred.cropped(to: maskCI.extent)
            }
        }

        return maskCI
    }
}
