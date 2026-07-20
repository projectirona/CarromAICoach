import Foundation
import CoreGraphics

// MARK: - Recommendation Model
/// The final output of the AI analysis pipeline — a complete shot recommendation
/// with supporting data for display.

public struct Recommendation: Sendable, Codable, Identifiable {
    
    /// Unique recommendation identifier.
    public let id: String
    
    /// The recommended shot.
    public let shot: Shot
    
    /// Success probability (0.0 to 1.0).
    public let probability: Double
    
    /// Number of coins that are currently pocketable with direct/rebound shots.
    public let pocketableCoinsCount: Int
    
    /// List of all pocketable coins (for display).
    public let pocketableCoins: [PocketableCoin]
    
    /// Human-readable reasoning for the recommendation.
    public let reasoning: String
    
    /// Board snapshot at the time of analysis (for overlay rendering).
    public let boardSnapshot: Board
    
    /// Analysis duration in seconds.
    public let analysisTime: TimeInterval
    
    /// Timestamp of the recommendation.
    public let timestamp: Date
    
    // MARK: - Initialization
    
    public init(
        shot: Shot,
        probability: Double,
        pocketableCoins: [PocketableCoin],
        reasoning: String,
        boardSnapshot: Board,
        analysisTime: TimeInterval
    ) {
        self.id = UUID().uuidString
        self.shot = shot
        self.probability = probability
        self.pocketableCoinsCount = pocketableCoins.count
        self.pocketableCoins = pocketableCoins
        self.reasoning = reasoning
        self.boardSnapshot = boardSnapshot
        self.analysisTime = analysisTime
        self.timestamp = Date()
    }
    
    // MARK: - Display Helpers
    
    /// Probability as a percentage string.
    public var probabilityPercent: String {
        "\(Int(probability * 100))%"
    }
    
    /// Shot type display name.
    public var shotTypeDisplay: String {
        shot.shotType.displayName
    }
    
    /// Target coin type display.
    public var targetCoinDisplay: String {
        shot.targetCoin.coinType.displayName
    }
    
    /// Target pocket display.
    public var targetPocketDisplay: String {
        shot.targetPocket.displayName
    }
    
    /// Power level display (1-10).
    public var powerDisplay: Int {
        shot.displayPower
    }
}

// MARK: - Pocketable Coin
/// A coin that the strategy engine has determined can be pocketed.

public struct PocketableCoin: Sendable, Codable, Identifiable {
    
    public let id: String
    
    /// The coin that can be pocketed.
    public let coin: Coin
    
    /// Which pocket it can be sent to.
    public let targetPocket: PocketID
    
    /// Best estimated probability for this specific coin-pocket pair.
    public let probability: Double
    
    /// Shot type required (direct, single rebound, etc.).
    public let shotType: ShotType
    
    public init(coin: Coin, targetPocket: PocketID, probability: Double, shotType: ShotType) {
        self.id = "\(coin.id)_\(targetPocket.rawValue)"
        self.coin = coin
        self.targetPocket = targetPocket
        self.probability = probability
        self.shotType = shotType
    }
}
