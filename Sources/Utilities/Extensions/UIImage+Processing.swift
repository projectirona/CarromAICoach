import UIKit
import CoreImage

// MARK: - UIImage Processing Extensions
/// Image processing utilities for camera frame analysis and board detection.

extension UIImage {
    
    // MARK: - Blur Detection
    
    /// Calculate the Laplacian variance of the image as a blur metric.
    /// Higher values indicate a sharper image.
    /// Returns nil if the image cannot be processed.
    public func laplacianVariance() -> Double? {
        guard let cgImage = self.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIEdges")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext(options: nil)
        let extent = outputImage.extent
        
        // Sample center region for performance
        let sampleSize: CGFloat = min(extent.width, extent.height, 200)
        let sampleRect = CGRect(
            x: extent.midX - sampleSize / 2,
            y: extent.midY - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )
        
        guard let bitmap = context.createCGImage(outputImage, from: sampleRect) else {
            return nil
        }
        
        // Calculate mean intensity as a proxy for edge strength (sharpness)
        let dataProvider = bitmap.dataProvider
        guard let data = dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else {
            return nil
        }
        
        let byteCount = CFDataGetLength(data)
        let bytesPerPixel = bitmap.bitsPerPixel / 8
        let pixelCount = byteCount / bytesPerPixel
        
        guard pixelCount > 0 else { return nil }
        
        var sum: Double = 0
        var sumSq: Double = 0
        
        for i in stride(from: 0, to: byteCount, by: bytesPerPixel) {
            let intensity = Double(ptr[i])
            sum += intensity
            sumSq += intensity * intensity
        }
        
        let mean = sum / Double(pixelCount)
        let variance = (sumSq / Double(pixelCount)) - (mean * mean)
        
        return variance
    }
    
    // MARK: - Resizing
    
    /// Resize the image to the target size, maintaining aspect ratio if specified.
    public func resized(to targetSize: CGSize, maintainAspectRatio: Bool = true) -> UIImage? {
        let size: CGSize
        
        if maintainAspectRatio {
            let widthRatio = targetSize.width / self.size.width
            let heightRatio = targetSize.height / self.size.height
            let ratio = min(widthRatio, heightRatio)
            size = CGSize(
                width: self.size.width * ratio,
                height: self.size.height * ratio
            )
        } else {
            size = targetSize
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Cropping
    
    /// Crop the image to the specified rectangle.
    public func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        // Convert from UIImage coordinates to CGImage coordinates (flip Y)
        let scale = self.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }
    
    // MARK: - Grayscale
    
    /// Convert the image to grayscale.
    public func grayscaled() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext(options: nil)
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: outputCGImage, scale: scale, orientation: imageOrientation)
    }
    
    // MARK: - Pixel Buffer
    
    /// Convert UIImage to CVPixelBuffer for Core ML inference.
    public func toPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        guard let cgImage = self.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}
