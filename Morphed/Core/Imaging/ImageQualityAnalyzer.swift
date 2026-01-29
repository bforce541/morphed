// morphed-ios/Morphed/Core/Imaging/ImageQualityAnalyzer.swift

import UIKit
import CoreImage
import Accelerate

enum ImageQualityAnalyzer {
    static func averageLuminance(for image: UIImage) -> CGFloat? {
        guard let ciImage = CIImage(image: image)?.oriented(forExifOrientation: image.exifOrientation) else {
            return nil
        }
        let extent = ciImage.extent
        guard !extent.isEmpty else { return nil }

        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        guard let outputImage = filter?.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
        context.render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let r = CGFloat(pixel[0]) / 255.0
        let g = CGFloat(pixel[1]) / 255.0
        let b = CGFloat(pixel[2]) / 255.0
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    static func laplacianVariance(for image: UIImage, maxDimension: CGFloat = 512) -> CGFloat? {
        guard let cgImage = image.cgImage else { return nil }

        let scale = min(1.0, maxDimension / max(CGFloat(cgImage.width), CGFloat(cgImage.height)))
        let targetWidth = Int(CGFloat(cgImage.width) * scale)
        let targetHeight = Int(CGFloat(cgImage.height) * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(colorSpace),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(
                CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            ),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        var sourceBuffer = vImage_Buffer()
        defer { free(sourceBuffer.data) }
        guard vImageBuffer_InitWithCGImage(
            &sourceBuffer,
            &format,
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags)
        ) == kvImageNoError else {
            return nil
        }

        var scaledBuffer = vImage_Buffer()
        defer { free(scaledBuffer.data) }
        guard vImageBuffer_Init(
            &scaledBuffer,
            vImagePixelCount(targetHeight),
            vImagePixelCount(targetWidth),
            32,
            vImage_Flags(kvImageNoFlags)
        ) == kvImageNoError else {
            return nil
        }

        guard vImageScale_ARGB8888(
            &sourceBuffer,
            &scaledBuffer,
            nil,
            vImage_Flags(kvImageHighQualityResampling)
        ) == kvImageNoError else {
            return nil
        }

        var grayBuffer = vImage_Buffer()
        defer { free(grayBuffer.data) }
        guard vImageBuffer_Init(
            &grayBuffer,
            scaledBuffer.height,
            scaledBuffer.width,
            8,
            vImage_Flags(kvImageNoFlags)
        ) == kvImageNoError else {
            return nil
        }

        let rgbToLuma: [Int16] = [54, 183, 19, 0]
        vImageMatrixMultiply_ARGB8888ToPlanar8(
            &scaledBuffer,
            &grayBuffer,
            rgbToLuma,
            8,
            nil,
            0,
            vImage_Flags(kvImageNoFlags)
        )

        let count = Int(grayBuffer.width * grayBuffer.height)
        var floatPixels = [Float](repeating: 0, count: count)
        let src = UnsafePointer(grayBuffer.data.assumingMemoryBound(to: UInt8.self))
        vDSP_vfltu8(
            src,
            1,
            &floatPixels,
            1,
            vDSP_Length(count)
        )

        var floatBuffer = vImage_Buffer(
            data: &floatPixels,
            height: grayBuffer.height,
            width: grayBuffer.width,
            rowBytes: Int(grayBuffer.width) * MemoryLayout<Float>.size
        )

        var laplacianPixels = [Float](repeating: 0, count: count)
        var laplacianBuffer = vImage_Buffer(
            data: &laplacianPixels,
            height: grayBuffer.height,
            width: grayBuffer.width,
            rowBytes: Int(grayBuffer.width) * MemoryLayout<Float>.size
        )

        let kernel: [Float] = [
            0, 1, 0,
            1, -4, 1,
            0, 1, 0
        ]

        vImageConvolve_PlanarF(
            &floatBuffer,
            &laplacianBuffer,
            nil,
            0,
            0,
            kernel,
            3,
            3,
            0,
            vImage_Flags(kvImageEdgeExtend)
        )

        var mean: Float = 0
        vDSP_meanv(laplacianPixels, 1, &mean, vDSP_Length(count))

        var squared = [Float](repeating: 0, count: count)
        vDSP_vsq(laplacianPixels, 1, &squared, 1, vDSP_Length(count))
        var meanSquare: Float = 0
        vDSP_meanv(squared, 1, &meanSquare, vDSP_Length(count))

        let variance = max(0, meanSquare - mean * mean)
        return CGFloat(variance)
    }
}
