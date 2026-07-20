import Foundation
import CoreGraphics

// MARK: - Score Weights
/// Tunable weights for the shot evaluation criteria.
/// Each weight controls how important a specific factor is in the overall shot ranking.

public struct ScoreWeights: Sendable {
    
    /// Weight for pocket probability (physics sim result).
    public var pocketProbability: Double
    
    /// Weight for ease of execution (angle/power tolerance).
    public var easeOfExecution: Double
    
    /// Weight for resulting board position quality.
    public var futurePosition: Double
    
    /// Weight for queen pocketing opportunity.
    public var queenOpportunity: Double
    
    /// Weight for ability to cover the queen on the same shot.
    public var coverOpportunity: Double
    
    /// Weight for risk of fouling (pocketing the striker).
    public var foulRisk: Double
    
    /// Weight for potential to unblock clustered coins.
    public var unblockPotential: Double
    
    /// Weight for avoiding leaving easy shots for the opponent.
    public var opponentAdvantage: Double
    
    // MARK: - Defaults
    
    /// Default weights as specified in the project plan.
    public static let `default` = ScoreWeights(
        pocketProbability: 0.30,
        easeOfExecution: 0.15,
        futurePosition: 0.15,
        queenOpportunity: 0.10,
        coverOpportunity: 0.05,
        foulRisk: 0.10,
        unblockPotential: 0.05,
        opponentAdvantage: 0.10
    )
    
    /// Aggressive weights — prioritize pocketing coins.
    public static let aggressive = ScoreWeights(
        pocketProbability: 0.40,
        easeOfExecution: 0.10,
        futurePosition: 0.10,
        queenOpportunity: 0.15,
        coverOpportunity: 0.05,
        foulRisk: 0.05,
        unblockPotential: 0.05,
        opponentAdvantage: 0.10
    )
    
    /// Defensive weights — prioritize safety and board control.
    public static let defensive = ScoreWeights(
        pocketProbability: 0.20,
        easeOfExecution: 0.15,
        futurePosition: 0.20,
        queenOpportunity: 0.05,
        coverOpportunity: 0.05,
        foulRisk: 0.20,
        unblockPotential: 0.05,
        opponentAdvantage: 0.10
    )
    
    // MARK: - Validation
    
    /// Total of all weights (should sum to 1.0).
    public var totalWeight: Double {
        pocketProbability + easeOfExecution + futurePosition +
        queenOpportunity + coverOpportunity + foulRisk +
        unblockPotential + opponentAdvantage
    }
    
    /// Whether the weights sum to approximately 1.0.
    public var isValid: Bool {
        abs(totalWeight - 1.0) < 0.001
    }
}
