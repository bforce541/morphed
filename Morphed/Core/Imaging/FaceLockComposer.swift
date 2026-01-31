// morphed-ios/Morphed/Core/Imaging/FaceLockComposer.swift

import UIKit
import Vision
import CoreImage
import ImageIO

struct FaceLockConfig {
    let padding: CGFloat = 18
    let paddingRatio: CGFloat = 0.06
    let feather: CGFloat = 10
    let featherRatio: CGFloat = 0.02
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

        if let mask = generateLandmarkMask(from: cgImage, config: config) {
            return mask
        }
        return generateRectMask(from: cgImage, config: config)
    }

    private static func generateLandmarkMask(from cgImage: CGImage, config: FaceLockConfig) -> CIImage? {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        let request = VNDetectFaceLandmarksRequest()
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let faces = request.results as? [VNFaceObservation],
              let face = selectPrimaryFace(faces) else {
            return nil
        }
        guard let contour = face.landmarks?.faceContour else {
            return nil
        }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let faceRect = VNImageRectForNormalizedRect(face.boundingBox, Int(imageSize.width), Int(imageSize.height))

        let padding = max(config.padding, max(faceRect.width, faceRect.height) * config.paddingRatio)
        let paddedRect = faceRect.insetBy(dx: -padding, dy: -padding)
        let clampedRect = paddedRect.intersection(CGRect(origin: .zero, size: imageSize))

        let points = contour.normalizedPoints.map { point -> CGPoint in
            CGPoint(
                x: faceRect.origin.x + point.x * faceRect.width,
                y: faceRect.origin.y + point.y * faceRect.height
            )
        }
        let scaledPoints = scalePoints(points, from: faceRect, to: clampedRect)

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))

        context.setFillColor(UIColor.white.cgColor)
        let path = UIBezierPath()
        if let first = scaledPoints.first {
            path.move(to: first)
            for point in scaledPoints.dropFirst() {
                path.addLine(to: point)
            }
            // Close up across the forehead by adding the top corners of the face rect.
            path.addLine(to: CGPoint(x: clampedRect.maxX, y: clampedRect.maxY))
            path.addLine(to: CGPoint(x: clampedRect.minX, y: clampedRect.maxY))
            path.close()
        }
        context.addPath(path.cgPath)
        context.fillPath()

        guard let maskImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        return blurMask(maskImage, feather: max(config.feather, max(faceRect.width, faceRect.height) * config.featherRatio))
    }

    private static func generateRectMask(from cgImage: CGImage, config: FaceLockConfig) -> CIImage? {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        let request = VNDetectFaceRectanglesRequest()
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let faces = request.results as? [VNFaceObservation],
              let face = selectPrimaryFace(faces) else {
            return nil
        }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let rect = face.boundingBox
        let faceRect = VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height))

        let padding = max(config.padding, max(faceRect.width, faceRect.height) * config.paddingRatio)
        let paddedRect = faceRect.insetBy(dx: -padding, dy: -padding)
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

        return blurMask(maskImage, feather: max(config.feather, max(faceRect.width, faceRect.height) * config.featherRatio))
    }

    private static func blurMask(_ image: UIImage, feather: CGFloat) -> CIImage? {
        guard var maskCI = CIImage(image: image) else { return nil }
        if let blur = CIFilter(name: "CIGaussianBlur") {
            blur.setValue(maskCI, forKey: kCIInputImageKey)
            blur.setValue(feather, forKey: kCIInputRadiusKey)
            if let blurred = blur.outputImage {
                maskCI = blurred.cropped(to: maskCI.extent)
            }
        }
        return maskCI
    }

    private static func selectPrimaryFace(_ faces: [VNFaceObservation]) -> VNFaceObservation? {
        faces.max { lhs, rhs in
            (lhs.boundingBox.width * lhs.boundingBox.height) < (rhs.boundingBox.width * rhs.boundingBox.height)
        }
    }

    private static func scalePoints(_ points: [CGPoint], from fromRect: CGRect, to toRect: CGRect) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let fromCenter = CGPoint(x: fromRect.midX, y: fromRect.midY)
        let scaleX = fromRect.width > 0 ? (toRect.width / fromRect.width) : 1.0
        let scaleY = fromRect.height > 0 ? (toRect.height / fromRect.height) : 1.0
        return points.map { point in
            let dx = point.x - fromCenter.x
            let dy = point.y - fromCenter.y
            let scaled = CGPoint(x: fromCenter.x + dx * scaleX, y: fromCenter.y + dy * scaleY)
            return CGPoint(
                x: min(max(scaled.x, toRect.minX), toRect.maxX),
                y: min(max(scaled.y, toRect.minY), toRect.maxY)
            )
        }
    }
}
