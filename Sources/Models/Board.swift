import Foundation
import CoreGraphics

// MARK: - Board Model
/// Represents the complete state of the carrom board including geometry and all detected pieces.

public struct Board: Sendable, Codable {
    
    // MARK: - Geometry
    
    /// The four corners of the detected board in the original camera image (pixel coordinates).
    /// Order: top-left, top-right, bottom-right, bottom-left.
    public var corners: [CGPoint]
    
    /// The four pockets.
    public let pockets: [Pocket]
    
    /// Playing area bounding rectangle in normalized coordinates.
    public let playingArea: CGRect
    
    /// Center of the board in board coordinates (mm).
    public let center: CGPoint
    
    // MARK: - Detected Pieces
    
    /// All detected coins currently in play.
    public var coins: [Coin]
    
    /// The detected striker, if present.
    public var striker: Coin?
    
    /// The queen coin, if detected and in play.
    public var queen: Coin? {
        coins.first { $0.isQueen && $0.isInPlay }
    }
    
    // MARK: - Initialization
    
    /// Create a board with detected geometry and pieces.
    public init(
        corners: [CGPoint],
        coins: [Coin] = [],
        striker: Coin? = nil
    ) {
        self.corners = corners
        self.pockets = Pocket.allPockets()
        self.playingArea = CGRect(x: 0, y: 0, width: 1, height: 1)
        self.center = CGPoint(x: 0, y: 0)
        self.coins = coins
        self.striker = striker
    }
    
    // MARK: - Queries
    
    /// Get all coins of a specific type.
    public func coins(ofType type: DetectionType) -> [Coin] {
        coins.filter { $0.coinType == type && $0.isInPlay }
    }
    
    /// Get all coins belonging to the given player color.
    public func playerCoins(for color: PlayerColor) -> [Coin] {
        coins.filter { $0.belongsTo(playerColor: color) && $0.isInPlay }
    }
    
    /// Get all opponent coins.
    public func opponentCoins(for playerColor: PlayerColor) -> [Coin] {
        let opponentColor: PlayerColor = playerColor == .black ? .white : .black
        return playerCoins(for: opponentColor)
    }
    
    /// Count of remaining player coins.
    public func remainingCount(for color: PlayerColor) -> Int {
        playerCoins(for: color).count
    }
    
    /// All coins currently in play (visible, not pocketed).
    public var activeCoins: [Coin] {
        coins.filter { $0.isInPlay }
    }
    
    /// Total number of coins on the board.
    public var activeCoinCount: Int {
        activeCoins.count
    }
    
    /// Whether the queen is still on the board.
    public var isQueenOnBoard: Bool {
        queen != nil
    }
    
    /// Check if a position is within the playing area bounds.
    public func isWithinBounds(_ point: CGPoint) -> Bool {
        let halfArea = CGFloat(BoardConfig.halfPlayingArea)
        return abs(point.x) <= halfArea && abs(point.y) <= halfArea
    }
    
    /// Find the nearest pocket to a given point.
    public func nearestPocket(to point: CGPoint) -> Pocket {
        pockets.min { p1, p2 in
            point.distanceSquared(to: p1.positionMM) < point.distanceSquared(to: p2.positionMM)
        } ?? pockets[0]
    }
}

// MARK: - Board Factory

extension Board {
    
    /// Create an empty board with default geometry (useful for testing).
    public static func empty() -> Board {
        let half = CGFloat(BoardConfig.halfPlayingArea)
        let corners = [
            CGPoint(x: -half, y: -half),  // Top-left
            CGPoint(x:  half, y: -half),  // Top-right
            CGPoint(x:  half, y:  half),  // Bottom-right
            CGPoint(x: -half, y:  half)   // Bottom-left
        ]
        return Board(corners: corners)
    }
}
