import Foundation
import UIKit
import CoreImage

// MARK: - Perspective Corrector
/// Transforms a skewed camera image of the carrom board into a top-down (bird's eye) view
/// using Core Image perspective correction.

public final class PerspectiveCorrector: Sendable {
    
    private let context: CIContext
    
    /// The target output size for the corrected image (square).
    public let outputSize: CGSize
    
    public init(outputSize: CGSize = CGSize(width: 800, height: 800)) {
        self.context = CIContext(options: [.useSoftwareRenderer: false])
        self.outputSize = outputSize
    }
    
    // MARK: - Correction
    
    /// Apply perspective correction to transform the board region into a top-down view.
    ///
    /// - Parameters:
    ///   - image: The original camera image.
    ///   - corners: The four board corners in image pixel coordinates (TL, TR, BR, BL).
    /// - Returns: The perspective-corrected top-down board image, or nil on failure.
    public func correct(image: UIImage, corners: [CGPoint]) -> UIImage? {
        guard corners.count == 4 else {
            Log.vision.error("Perspective correction requires exactly 4 corners, got \(corners.count)")
            return nil
        }
        
        guard let cgImage = image.cgImage else {
            Log.vision.error("Failed to get CGImage for perspective correction")
            return nil
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let imageHeight = CGFloat(cgImage.height)
        
        // CIImage uses bottom-left origin, so flip Y coordinates
        let topLeft = CIVector(x: corners[0].x, y: imageHeight - corners[0].y)
        let topRight = CIVector(x: corners[1].x, y: imageHeight - corners[1].y)
        let bottomRight = CIVector(x: corners[2].x, y: imageHeight - corners[2].y)
        let bottomLeft = CIVector(x: corners[3].x, y: imageHeight - corners[3].y)
        
        // Apply perspective correction filter
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            Log.vision.error("CIPerspectiveCorrection filter not available")
            return nil
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(topLeft, forKey: "inputTopLeft")
        filter.setValue(topRight, forKey: "inputTopRight")
        filter.setValue(bottomRight, forKey: "inputBottomRight")
        filter.setValue(bottomLeft, forKey: "inputBottomLeft")
        
        guard let outputCIImage = filter.outputImage else {
            Log.vision.error("Perspective correction filter produced no output")
            return nil
        }
        
        // Scale to target output size
        let scaleX = outputSize.width / outputCIImage.extent.width
        let scaleY = outputSize.height / outputCIImage.extent.height
        let scaledImage = outputCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let outputCGImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            Log.vision.error("Failed to render corrected image")
            return nil
        }
        
        Log.vision.info("Perspective correction complete: \(Int(outputSize.width))×\(Int(outputSize.height))")
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // MARK: - Homography Matrix
    
    /// Compute the 3×3 homography matrix mapping source corners to a unit square.
    /// Useful for coordinate transformation without re-rendering the image.
    ///
    /// - Parameter corners: The four board corners in image coordinates (TL, TR, BR, BL).
    /// - Returns: The 3×3 homography matrix as a flat array [a, b, c, d, e, f, g, h, 1],
    ///            or nil if the matrix cannot be computed.
    public func computeHomography(corners: [CGPoint]) -> [CGFloat]? {
        guard corners.count == 4 else { return nil }
        
        // Source points (board corners in image)
        let src = corners
        
        // Destination points (unit square scaled to output size)
        let dst: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: outputSize.width, y: 0),
            CGPoint(x: outputSize.width, y: outputSize.height),
            CGPoint(x: 0, y: outputSize.height)
        ]
        
        // Solve the 8-equation system for homography coefficients
        // Using direct linear transform (DLT) method
        // H maps src -> dst: dst = H * src (in homogeneous coordinates)
        
        // Build the 8×8 system Ah = b
        var A = [[CGFloat]](repeating: [CGFloat](repeating: 0, count: 8), count: 8)
        var b = [CGFloat](repeating: 0, count: 8)
        
        for i in 0..<4 {
            let sx = src[i].x, sy = src[i].y
            let dx = dst[i].x, dy = dst[i].y
            
            A[2*i]   = [sx, sy, 1, 0, 0, 0, -dx*sx, -dx*sy]
            A[2*i+1] = [0, 0, 0, sx, sy, 1, -dy*sx, -dy*sy]
            b[2*i]   = dx
            b[2*i+1] = dy
        }
        
        // Gaussian elimination
        guard let h = solveLinearSystem(A, b) else { return nil }
        
        // Homography matrix: [h0, h1, h2, h3, h4, h5, h6, h7, 1]
        return h + [1.0]
    }
    
    /// Solve an n×n linear system Ax = b using Gaussian elimination with partial pivoting.
    private func solveLinearSystem(_ A: [[CGFloat]], _ b: [CGFloat]) -> [CGFloat]? {
        let n = b.count
        var aug = A
        var rhs = b
        
        // Forward elimination
        for col in 0..<n {
            // Partial pivoting
            var maxRow = col
            var maxVal = abs(aug[col][col])
            for row in (col+1)..<n {
                if abs(aug[row][col]) > maxVal {
                    maxVal = abs(aug[row][col])
                    maxRow = row
                }
            }
            
            if maxVal < 1e-10 { return nil }  // Singular matrix
            
            aug.swapAt(col, maxRow)
            rhs.swapAt(col, maxRow)
            
            let pivot = aug[col][col]
            for row in (col+1)..<n {
                let factor = aug[row][col] / pivot
                for k in col..<n {
                    aug[row][k] -= factor * aug[col][k]
                }
                rhs[row] -= factor * rhs[col]
            }
        }
        
        // Back substitution
        var x = [CGFloat](repeating: 0, count: n)
        for i in stride(from: n-1, through: 0, by: -1) {
            var sum: CGFloat = rhs[i]
            for j in (i+1)..<n {
                sum -= aug[i][j] * x[j]
            }
            x[i] = sum / aug[i][i]
        }
        
        return x
    }
}
