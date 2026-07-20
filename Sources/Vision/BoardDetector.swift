import Foundation
import UIKit
@preconcurrency import Vision
import CoreGraphics

// MARK: - Board Detector
/// Detects the carrom board quadrilateral in a camera image using Apple's Vision framework.
/// Finds the four corners for perspective correction.

public final class BoardDetector: Sendable {
    
    // MARK: - Detection Result
    
    /// Result of board detection with corner positions.
    public struct DetectionResult: @unchecked Sendable {
        /// The four corners in image pixel coordinates.
        /// Order: top-left, top-right, bottom-right, bottom-left.
        public let corners: [CGPoint]
        
        /// Confidence of the detection (0.0 to 1.0).
        public let confidence: Float
        
        /// The detected rectangle observation from Vision.
        public let observation: VNRectangleObservation
        
        public init(corners: [CGPoint], confidence: Float, observation: VNRectangleObservation) {
            self.corners = corners
            self.confidence = confidence
            self.observation = observation
        }
        
        /// Whether this is a valid board detection.
        public var isValid: Bool {
            confidence >= AppConfig.boardDetectionConfidenceThreshold && corners.count == 4
        }
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Detection
    
    /// Detect the carrom board rectangle in the given image.
    ///
    /// - Parameter image: The camera frame to analyze.
    /// - Returns: Detection result with corners, or nil if no board found.
    public func detectBoard(in image: UIImage) async -> DetectionResult? {
        guard let cgImage = image.cgImage else {
            Log.boardDetection.error("Failed to get CGImage from UIImage")
            return nil
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    Log.boardDetection.error("Rectangle detection failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let results = request.results as? [VNRectangleObservation],
                      let bestRect = results.first else {
                    Log.boardDetection.info("No rectangles detected")
                    continuation.resume(returning: nil)
                    return
                }
                
                // Convert normalized Vision coordinates to pixel coordinates
                let corners = Self.convertCorners(bestRect, imageSize: imageSize)
                
                let result = DetectionResult(
                    corners: corners,
                    confidence: bestRect.confidence,
                    observation: bestRect
                )
                
                Log.boardDetection.info(
                    "Board detected: confidence=\(bestRect.confidence, format: .fixed(precision: 2))"
                )
                
                continuation.resume(returning: result)
            }
            
            // Configure rectangle detection for large, square-ish rectangles
            request.minimumConfidence = 0.5
            request.maximumObservations = 1
            request.minimumAspectRatio = 0.8   // Board is nearly square
            request.maximumAspectRatio = 1.2
            request.minimumSize = 0.3          // Board should fill at least 30% of frame
            request.quadratureTolerance = 15   // Allow slight perspective skew
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                Log.boardDetection.error("Vision request failed: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert VNRectangleObservation normalized coordinates to pixel coordinates.
    /// Vision uses bottom-left origin; we convert to top-left origin.
    private static func convertCorners(
        _ observation: VNRectangleObservation,
        imageSize: CGSize
    ) -> [CGPoint] {
        let width = imageSize.width
        let height = imageSize.height
        
        // Vision coordinates: (0,0) = bottom-left, (1,1) = top-right
        // UIKit coordinates: (0,0) = top-left
        func convert(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: point.x * width,
                y: (1.0 - point.y) * height
            )
        }
        
        return [
            convert(observation.topLeft),      // Top-left
            convert(observation.topRight),     // Top-right
            convert(observation.bottomRight),  // Bottom-right
            convert(observation.bottomLeft)    // Bottom-left
        ]
    }
}
