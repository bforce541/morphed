// Morphed/Core/Utils/WatermarkRenderer.swift

import UIKit

enum WatermarkRenderer {
    /// Adds a simple Morphed watermark to the bottom-right corner of an image.
    /// If drawing fails, the original image is returned.
    static func addWatermark(to image: UIImage) -> UIImage {
        let scale = image.scale
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        
        let watermarkText = "MORPHED PREVIEW"
        let fontSize = min(size.width, size.height) * 0.04
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.85),
            .paragraphStyle: paragraph,
            .shadow: {
                let shadow = NSShadow()
                shadow.shadowColor = UIColor.black.withAlphaComponent(0.6)
                shadow.shadowBlurRadius = 4
                shadow.shadowOffset = CGSize(width: 0, height: 1)
                return shadow
            }()
        ]
        
        let margin: CGFloat = fontSize * 0.6
        let textRect = CGRect(
            x: margin,
            y: size.height - fontSize * 2 - margin,
            width: size.width - margin * 2,
            height: fontSize * 2
        )
        
        watermarkText.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}


