// morphed-ios/Morphed/Core/Utils/ImageUtils.swift

import UIKit

enum ImageUtils {
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        
        let ratio: CGFloat
        if size.width > size.height {
            ratio = maxDimension / size.width
        } else {
            ratio = maxDimension / size.height
        }
        
        guard ratio < 1.0 else {
            return image
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    static func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    static func compressToJPEG(_ image: UIImage, quality: CGFloat) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    static func base64Encode(_ data: Data) -> String {
        return data.base64EncodedString()
    }
    
    static func decodeBase64(_ base64String: String) -> Data? {
        return Data(base64Encoded: base64String)
    }
    
    static func imageFromData(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}
