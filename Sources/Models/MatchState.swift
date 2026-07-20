import Foundation

// MARK: - Player Color
/// The player's chosen color for the match.

public enum PlayerColor: String, Sendable, CaseIterable, Codable {
    case black = "Black"
    case white = "White"
    
    /// The opponent's color.
    public var opponent: PlayerColor {
        switch self {
        case .black: return .white
        case .white: return .black
        }
    }
    
    /// Corresponding detection type.
    public var detectionType: DetectionType {
        switch self {
        case .black: return .blackCoin
        case .white: return .whiteCoin
        }
    }
}

// MARK: - Queen Status
/// Tracks the state of the queen during a match.

public enum QueenStatus: String, Sendable, Codable {
    /// Queen is still on the board.
    case onBoard = "On Board"
    
    /// Queen has been pocketed and needs to be covered.
    case pocketed = "Pocketed"
    
    /// Queen has been pocketed and covered (claimed).
    case covered = "Covered"
    
    /// Queen was pocketed by a foul and returned to center.
    case returned = "Returned"
}

// MARK: - Match State
/// Persistent state of the current match, updated after each scan.

public struct MatchState: Sendable, Codable, Identifiable {
    
    /// Unique match identifier.
    public let id: String
    
    /// The player's chosen color.
    public let playerColor: PlayerColor
    
    /// Current turn number (1-based).
    public var currentTurn: Int
    
    /// Number of remaining player coins on the board.
    public var remainingPlayerCoins: Int
    
    /// Number of remaining opponent coins on the board.
    public var remainingOpponentCoins: Int
    
    /// Current queen status.
    public var queenStatus: QueenStatus
    
    /// History of shots and recommendations.
    public var shotHistory: [ShotRecord]
    
    /// The most recent recommendation (for comparison with next scan).
    public var previousRecommendation: Recommendation?
    
    /// Match creation timestamp.
    public let createdAt: Date
    
    /// Last update timestamp.
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    /// Create a new match state.
    public init(playerColor: PlayerColor) {
        self.id = UUID().uuidString
        self.playerColor = playerColor
        self.currentTurn = 1
        self.remainingPlayerCoins = BoardConfig.blackCoinCount  // 9
        self.remainingOpponentCoins = BoardConfig.whiteCoinCount  // 9
        self.queenStatus = .onBoard
        self.shotHistory = []
        self.previousRecommendation = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - State Updates
    
    /// Advance to the next turn.
    public mutating func advanceTurn() {
        currentTurn += 1
        updatedAt = Date()
    }
    
    /// Update coin counts from the current board scan.
    public mutating func updateFromBoard(_ board: Board) {
        remainingPlayerCoins = board.remainingCount(for: playerColor)
        remainingOpponentCoins = board.remainingCount(for: playerColor.opponent)
        
        if board.isQueenOnBoard {
            if queenStatus == .pocketed {
                // Queen was returned to board after a foul
                queenStatus = .returned
            } else if queenStatus != .covered {
                queenStatus = .onBoard
            }
        } else if queenStatus == .onBoard {
            queenStatus = .pocketed
        }
        
        updatedAt = Date()
    }
    
    /// Record a recommendation for this turn.
    public mutating func recordRecommendation(_ recommendation: Recommendation) {
        previousRecommendation = recommendation
        shotHistory.append(ShotRecord(
            turn: currentTurn,
            recommendation: recommendation,
            timestamp: Date()
        ))
        updatedAt = Date()
    }
    
    // MARK: - Match Status
    
    /// Whether the player has won (all their coins pocketed).
    public var isPlayerFinished: Bool {
        remainingPlayerCoins == 0
    }
    
    /// Whether the opponent has won.
    public var isOpponentFinished: Bool {
        remainingOpponentCoins == 0
    }
}

// MARK: - Shot Record
/// A historical record of a turn's recommendation.

public struct ShotRecord: Sendable, Codable, Identifiable {
    public let id: String
    public let turn: Int
    public let recommendation: Recommendation
    public let timestamp: Date
    
    public init(turn: Int, recommendation: Recommendation, timestamp: Date) {
        self.id = UUID().uuidString
        self.turn = turn
        self.recommendation = recommendation
        self.timestamp = timestamp
    }
}
