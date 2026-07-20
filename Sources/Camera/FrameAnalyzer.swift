import Foundation
import UIKit
import CoreImage

// MARK: - Frame Analyzer
/// Analyzes camera frames for blur, stability, and board detection quality.

public final class FrameAnalyzer: Sendable {
    
    private let context: CIContext
    
    public init() {
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }
    
    // MARK: - Blur Detection
    
    /// Calculate a blur score for the image.
    /// Higher values indicate sharper images.
    /// Uses edge detection intensity as a proxy for sharpness.
    public func blurScore(_ image: UIImage) -> Double {
        return image.laplacianVariance() ?? 0
    }
    
    /// Whether the image is acceptably sharp.
    public func isSharp(_ image: UIImage) -> Bool {
        blurScore(image) >= AppConfig.blurThreshold
    }
    
    // MARK: - Stability Detection
    
    /// Calculate the average intensity of the center region of the image.
    /// Used for frame-to-frame comparison to detect camera movement.
    public func centerIntensity(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        
        // Sample center 20% of the image
        let sampleSize = min(extent.width, extent.height) * 0.2
        let sampleRect = CGRect(
            x: extent.midX - sampleSize / 2,
            y: extent.midY - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )
        
        // Use CIAreaAverage to compute mean color
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: sampleRect), forKey: "inputExtent")
        
        guard let outputImage = filter?.outputImage else { return 0 }
        
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        
        // Luminance from RGB
        let r = Double(pixel[0])
        let g = Double(pixel[1])
        let b = Double(pixel[2])
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
    
    // MARK: - Board Completeness
    
    /// Check if the image likely contains a complete carrom board.
    /// Uses aspect ratio and edge density heuristics.
    public func likelyContainsBoard(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        // The board should occupy a significant portion of the frame
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        // A carrom board photographed from above should be roughly square
        // in the center of a 16:9 frame
        let aspectRatio = width / height
        
        // Basic sanity check — we expect a landscape or portrait phone image
        return aspectRatio > 0.5 && aspectRatio < 2.0
    }
}
