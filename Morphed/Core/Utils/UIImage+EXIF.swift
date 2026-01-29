// morphed-ios/Morphed/Core/Utils/UIImage+EXIF.swift

import UIKit

extension UIImage {
    var exifOrientation: Int32 {
        switch imageOrientation {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }
}
