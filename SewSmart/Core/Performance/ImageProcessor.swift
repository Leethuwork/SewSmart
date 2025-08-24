import Foundation
import UIKit
import os.log

/// High-performance image processing utilities
actor ImageProcessor {
    static let shared = ImageProcessor()
    
    private let logger = Logger(subsystem: "com.sewsmart.performance", category: "ImageProcessor")
    
    private init() {}
    
    /// Resize image to target size while maintaining aspect ratio
    func resizeImage(_ image: UIImage, to targetSize: CGSize, quality: ImageQuality = .medium) async -> UIImage? {
        return self.performResize(image, to: targetSize, quality: quality)
    }
    
    private func performResize(_ image: UIImage, to targetSize: CGSize, quality: ImageQuality) -> UIImage? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Calculate scaling factor to maintain aspect ratio
        let aspectRatio = image.size.width / image.size.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        var scaledSize: CGSize
        if aspectRatio > targetAspectRatio {
            // Image is wider than target
            scaledSize = CGSize(width: targetSize.width, height: targetSize.width / aspectRatio)
        } else {
            // Image is taller than target
            scaledSize = CGSize(width: targetSize.height * aspectRatio, height: targetSize.height)
        }
        
        // Ensure we don't scale up
        if scaledSize.width > image.size.width || scaledSize.height > image.size.height {
            scaledSize = image.size
        }
        
        // Create graphics context
        let format = UIGraphicsImageRendererFormat()
        format.scale = quality.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
        
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let ms = processingTime * 1000
        let msg = "Resized image from \(image.size) to \(scaledSize) in \(String(format: "%.1f", ms))ms"
        self.logger.debug("\(msg, privacy: .public)")
        
        return resizedImage
    }
    
    /// Compress image data while maintaining quality
    func compressImage(_ image: UIImage, quality: ImageQuality = .medium) async -> Data? {
        return self.performCompression(image, quality: quality)
    }
    
    private func performCompression(_ image: UIImage, quality: ImageQuality) -> Data? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let compressionQuality = quality.compressionQuality
        let data = image.jpegData(compressionQuality: compressionQuality)
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let ms = processingTime * 1000
        let originalSize = image.pngData()?.count ?? 0
        let compressedSize = data?.count ?? 0
        
        let msg = "Compressed image from \(originalSize) to \(compressedSize) bytes (\(String(format: "%.0f", compressionQuality * 100))% quality) in \(String(format: "%.1f", ms))ms"
        self.logger.debug("\(msg, privacy: .public)")
        
        return data
    }
    
    /// Generate thumbnail with specific size
    func generateThumbnail(from image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) async -> UIImage? {
        return await resizeImage(image, to: size, quality: .low)
    }
    
    /// Process image for storage (resize + compress)
    func processForStorage(_ image: UIImage, maxSize: CGSize = CGSize(width: 1024, height: 1024)) async -> ProcessedImage? {
        guard let resizedImage = await resizeImage(image, to: maxSize, quality: .medium),
              let compressedData = await compressImage(resizedImage, quality: .medium) else {
            self.logger.error("Failed to process image for storage")
            return nil
        }
        
        return ProcessedImage(image: resizedImage, data: compressedData)
    }
}

// MARK: - Supporting Types

enum ImageQuality {
    case low
    case medium  
    case high
    case original
    
    var scale: CGFloat {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        case .original: return UIScreen.main.scale
        }
    }
    
    var compressionQuality: CGFloat {
        switch self {
        case .low: return 0.5
        case .medium: return 0.8
        case .high: return 0.9
        case .original: return 1.0
        }
    }
}

struct ProcessedImage {
    let image: UIImage
    let data: Data
    
    var sizeInBytes: Int {
        return data.count
    }
    
    var compressionRatio: Double {
        guard let originalSize = image.pngData()?.count, originalSize > 0 else { return 0 }
        return Double(data.count) / Double(originalSize)
    }
}