import Foundation
import CoreGraphics
import Vision

// MARK: - AR State
/// Represents the live state of the AR overlay.

public struct ARState: @unchecked Sendable {
    /// The computed recommendation to display.
    public let recommendation: Recommendation
    
    /// The raw board corners detected in the camera frame.
    public let boardObservation: VNRectangleObservation
    
    public init(recommendation: Recommendation, boardObservation: VNRectangleObservation) {
        self.recommendation = recommendation
        self.boardObservation = boardObservation
    }
}
