import Foundation

// MARK: - Board Configuration
/// Fixed physical dimensions for a standard 52-inch carrom board.
/// All measurements are in millimeters unless otherwise noted.
/// Reference: International Carrom Federation (ICF) specifications.

public struct BoardConfig: Sendable {
    
    // MARK: - Board Dimensions
    
    /// Total outer board size (52 inches = 1320.8 mm), rounded to nearest mm.
    public static let outerDimension: Double = 1321.0
    
    /// Inner playing surface dimension (29 inches = 736.6 mm).
    /// This is the area bounded by the cushion rails.
    public static let playingAreaDimension: Double = 737.0
    
    /// Half of the playing area dimension, used for coordinate calculations.
    public static let halfPlayingArea: Double = playingAreaDimension / 2.0
    
    // MARK: - Pocket Dimensions
    
    /// Pocket opening diameter (44.5 mm standard).
    public static let pocketDiameter: Double = 44.5
    
    /// Pocket radius.
    public static let pocketRadius: Double = pocketDiameter / 2.0
    
    /// Pocket capture radius — a coin is considered pocketed if its center
    /// enters within this radius of the pocket center.
    /// Slightly smaller than the physical pocket to account for coin radius.
    public static let pocketCaptureRadius: Double = 22.25
    
    /// Pocket positions in normalized coordinates (0.0 to 1.0).
    /// Origin at top-left of playing area.
    public static let pocketPositions: [(x: Double, y: Double)] = [
        (x: 0.0, y: 0.0),   // Top-left
        (x: 1.0, y: 0.0),   // Top-right
        (x: 0.0, y: 1.0),   // Bottom-left
        (x: 1.0, y: 1.0)    // Bottom-right
    ]
    
    /// Pocket positions in millimeters from center of playing area.
    public static let pocketPositionsMM: [(x: Double, y: Double)] = [
        (x: -halfPlayingArea, y: -halfPlayingArea),  // Top-left
        (x:  halfPlayingArea, y: -halfPlayingArea),  // Top-right
        (x: -halfPlayingArea, y:  halfPlayingArea),  // Bottom-left
        (x:  halfPlayingArea, y:  halfPlayingArea)   // Bottom-right
    ]
    
    // MARK: - Coin Dimensions
    
    /// Standard carrom coin diameter (31 mm).
    public static let coinDiameter: Double = 31.0
    
    /// Coin radius.
    public static let coinRadius: Double = coinDiameter / 2.0
    
    /// Queen diameter (same as regular coins).
    public static let queenDiameter: Double = 31.0
    
    /// Queen radius.
    public static let queenRadius: Double = queenDiameter / 2.0
    
    // MARK: - Striker Dimensions
    
    /// Fixed striker diameter (75 mm as specified).
    public static let strikerDiameter: Double = 75.0
    
    /// Striker radius.
    public static let strikerRadius: Double = strikerDiameter / 2.0
    
    // MARK: - Mass (grams)
    
    /// Coin mass in grams.
    public static let coinMass: Double = 5.0
    
    /// Striker mass in grams.
    public static let strikerMass: Double = 15.0
    
    // MARK: - Baseline
    
    /// Distance from the edge of the playing area to the baseline (47 mm standard).
    public static let baselineOffset: Double = 47.0
    
    /// Baseline length — extends across the playing area, offset from each side by
    /// the baseline circle radius.
    public static let baselineCircleRadius: Double = 25.0
    
    /// Baseline Y position in mm from center (player sits at bottom, y positive).
    /// The baseline is near the bottom edge.
    public static let baselineY: Double = halfPlayingArea - baselineOffset
    
    /// Baseline X range in mm from center.
    /// The striker can be placed anywhere along the baseline between the two circles.
    public static let baselineMinX: Double = -halfPlayingArea + baselineOffset + strikerRadius
    public static let baselineMaxX: Double = halfPlayingArea - baselineOffset - strikerRadius
    
    // MARK: - Center Circle
    
    /// Center circle diameter (170 mm standard).
    public static let centerCircleDiameter: Double = 170.0
    
    /// Center circle radius.
    public static let centerCircleRadius: Double = centerCircleDiameter / 2.0
    
    // MARK: - Coin Counts
    
    /// Number of black coins in a standard game.
    public static let blackCoinCount: Int = 9
    
    /// Number of white coins in a standard game.
    public static let whiteCoinCount: Int = 9
    
    /// Total number of coins (9 black + 9 white + 1 queen).
    public static let totalCoinCount: Int = 19
    
    private init() {}
}
