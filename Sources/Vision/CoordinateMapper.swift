import Foundation
import CoreGraphics

// MARK: - Coordinate Mapper
/// Bidirectional mapping between pixel coordinates in the perspective-corrected image
/// and board coordinates in millimeters (centered at board center).

public struct CoordinateMapper: Sendable {
    
    /// Size of the perspective-corrected image in pixels.
    public let imageSize: CGSize
    
    /// Playing area dimension in millimeters.
    public let boardDimensionMM: CGFloat
    
    /// Pixels per millimeter (conversion factor).
    public let pixelsPerMM: CGFloat
    
    // MARK: - Initialization
    
    /// Create a coordinate mapper for a given corrected image size.
    ///
    /// - Parameters:
    ///   - imageSize: Size of the perspective-corrected image (should be square).
    ///   - boardDimension: Playing area dimension in mm (default from BoardConfig).
    public init(
        imageSize: CGSize = CGSize(width: 800, height: 800),
        boardDimension: CGFloat = CGFloat(BoardConfig.playingAreaDimension)
    ) {
        self.imageSize = imageSize
        self.boardDimensionMM = boardDimension
        self.pixelsPerMM = imageSize.width / boardDimension
    }
    
    // MARK: - Pixel to Board Coordinates
    
    /// Convert pixel coordinates (0,0 at top-left) to board coordinates (0,0 at center, mm).
    ///
    /// - Parameter pixel: Point in pixel coordinates of the corrected image.
    /// - Returns: Point in board coordinates (mm from center).
    public func pixelToBoard(_ pixel: CGPoint) -> CGPoint {
        let boardX = (pixel.x - imageSize.width / 2.0) / pixelsPerMM
        let boardY = (pixel.y - imageSize.height / 2.0) / pixelsPerMM
        return CGPoint(x: boardX, y: boardY)
    }
    
    /// Convert pixel coordinates to normalized board coordinates (0.0 to 1.0).
    ///
    /// - Parameter pixel: Point in pixel coordinates.
    /// - Returns: Point in normalized coordinates (0,0 = top-left, 1,1 = bottom-right).
    public func pixelToNormalized(_ pixel: CGPoint) -> CGPoint {
        CGPoint(
            x: pixel.x / imageSize.width,
            y: pixel.y / imageSize.height
        )
    }
    
    // MARK: - Board to Pixel Coordinates
    
    /// Convert board coordinates (mm from center) to pixel coordinates.
    ///
    /// - Parameter board: Point in board coordinates (mm from center).
    /// - Returns: Point in pixel coordinates of the corrected image.
    public func boardToPixel(_ board: CGPoint) -> CGPoint {
        let pixelX = board.x * pixelsPerMM + imageSize.width / 2.0
        let pixelY = board.y * pixelsPerMM + imageSize.height / 2.0
        return CGPoint(x: pixelX, y: pixelY)
    }
    
    /// Convert board coordinates to normalized coordinates (0.0 to 1.0).
    ///
    /// - Parameter board: Point in board coordinates (mm from center).
    /// - Returns: Point in normalized coordinates.
    public func boardToNormalized(_ board: CGPoint) -> CGPoint {
        let normalized = boardToPixel(board)
        return pixelToNormalized(normalized)
    }
    
    // MARK: - Normalized to Board Coordinates
    
    /// Convert normalized coordinates (0.0 to 1.0) to board coordinates (mm from center).
    ///
    /// - Parameter normalized: Point in normalized coordinates.
    /// - Returns: Point in board coordinates (mm from center).
    public func normalizedToBoard(_ normalized: CGPoint) -> CGPoint {
        let pixel = CGPoint(
            x: normalized.x * imageSize.width,
            y: normalized.y * imageSize.height
        )
        return pixelToBoard(pixel)
    }
    
    // MARK: - Distance Conversions
    
    /// Convert a distance in pixels to millimeters.
    public func pixelsToMM(_ pixels: CGFloat) -> CGFloat {
        pixels / pixelsPerMM
    }
    
    /// Convert a distance in millimeters to pixels.
    public func mmToPixels(_ mm: CGFloat) -> CGFloat {
        mm * pixelsPerMM
    }
    
    // MARK: - Validation
    
    /// Check if a board coordinate is within the playing area.
    public func isWithinBounds(_ boardPoint: CGPoint) -> Bool {
        let halfBoard = boardDimensionMM / 2.0
        return abs(boardPoint.x) <= halfBoard && abs(boardPoint.y) <= halfBoard
    }
    
    /// Clamp a board coordinate to the playing area bounds.
    public func clampToBounds(_ boardPoint: CGPoint) -> CGPoint {
        let halfBoard = boardDimensionMM / 2.0
        return CGPoint(
            x: min(max(boardPoint.x, -halfBoard), halfBoard),
            y: min(max(boardPoint.y, -halfBoard), halfBoard)
        )
    }
}
