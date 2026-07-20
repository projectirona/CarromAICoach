import Foundation
import CoreGraphics

// MARK: - Shot Evaluator
/// Scores a candidate shot on 8 criteria, producing a weighted composite score.

public final class ShotEvaluator: @unchecked Sendable {
    
    // MARK: - Evaluated Shot
    
    /// A candidate shot with its evaluation scores.
    public struct EvaluatedShot: Sendable {
        public let candidate: ShotGenerator.CandidateShot
        public let scores: CriteriaScores
        public let compositeScore: Double
        public let simulationResult: PhysicsEngine.SimulationResult
    }
    
    /// Individual criterion scores (each 0.0 to 1.0, higher = better).
    public struct CriteriaScores: Sendable {
        public let pocketProbability: Double
        public let easeOfExecution: Double
        public let futurePosition: Double
        public let queenOpportunity: Double
        public let coverOpportunity: Double
        public let foulRisk: Double
        public let unblockPotential: Double
        public let opponentAdvantage: Double
    }
    
    // MARK: - Properties
    
    private let physicsEngine: PhysicsEngine
    private let weights: ScoreWeights
    
    // MARK: - Initialization
    
    public init(
        physicsEngine: PhysicsEngine = PhysicsEngine(),
        weights: ScoreWeights = .default
    ) {
        self.physicsEngine = physicsEngine
        self.weights = weights
    }
    
    // MARK: - Evaluation
    
    /// Evaluate a single candidate shot against the current board state.
    public func evaluate(
        candidate: ShotGenerator.CandidateShot,
        board: Board,
        playerColor: PlayerColor,
        matchState: MatchState
    ) -> EvaluatedShot {
        // Run physics simulation
        let simResult = physicsEngine.simulateShot(
            coins: board.coins + (board.striker.map { [$0] } ?? []),
            strikerPosition: candidate.strikerPosition,
            aimAngle: candidate.aimAngle,
            power: candidate.power
        )
        
        // Calculate individual criterion scores
        let scores = CriteriaScores(
            pocketProbability: scorePocketProbability(candidate: candidate, simResult: simResult),
            easeOfExecution: scoreEaseOfExecution(candidate: candidate),
            futurePosition: scoreFuturePosition(simResult: simResult, playerColor: playerColor),
            queenOpportunity: scoreQueenOpportunity(candidate: candidate, simResult: simResult, matchState: matchState),
            coverOpportunity: scoreCoverOpportunity(candidate: candidate, simResult: simResult, matchState: matchState),
            foulRisk: scoreFoulRisk(simResult: simResult),
            unblockPotential: scoreUnblockPotential(simResult: simResult, board: board, playerColor: playerColor),
            opponentAdvantage: scoreOpponentAdvantage(simResult: simResult, board: board, playerColor: playerColor)
        )
        
        // Compute weighted composite score
        let composite =
            scores.pocketProbability * weights.pocketProbability +
            scores.easeOfExecution * weights.easeOfExecution +
            scores.futurePosition * weights.futurePosition +
            scores.queenOpportunity * weights.queenOpportunity +
            scores.coverOpportunity * weights.coverOpportunity +
            scores.foulRisk * weights.foulRisk +
            scores.unblockPotential * weights.unblockPotential +
            scores.opponentAdvantage * weights.opponentAdvantage
        
        return EvaluatedShot(
            candidate: candidate,
            scores: scores,
            compositeScore: composite,
            simulationResult: simResult
        )
    }
    
    // MARK: - Scoring Functions
    
    /// Pocket probability: did the target coin reach the target pocket?
    private func scorePocketProbability(
        candidate: ShotGenerator.CandidateShot,
        simResult: PhysicsEngine.SimulationResult
    ) -> Double {
        let targetPocketed = simResult.pocketedBodies.contains {
            $0.bodyID == candidate.targetCoin.id && $0.pocketID == candidate.targetPocket
        }
        
        // Base score: 1.0 if pocketed, 0.0 if not
        var score: Double = targetPocketed ? 1.0 : 0.0
        
        // Bonus for pocketing additional player coins
        if targetPocketed {
            let extraPocketed = simResult.pocketedCoinCount - 1
            score += Double(extraPocketed) * 0.1  // Small bonus per extra coin
        }
        
        // If not pocketed, give partial credit based on how close the coin got to the pocket
        if !targetPocketed {
            let pocketPos = Pocket(id: candidate.targetPocket).positionMM
            if let finalBody = simResult.finalBodies.first(where: { $0.id == candidate.targetCoin.id }) {
                let distToPocket = finalBody.position.distance(to: pocketPos)
                let maxDist = CGFloat(BoardConfig.playingAreaDimension)
                let proximity = max(0, 1.0 - Double(distToPocket / maxDist))
                score = proximity * 0.3  // Partial credit, max 0.3
            }
        }
        
        return min(1.0, score)
    }
    
    /// Ease of execution: how forgiving is this shot?
    /// Penalizes long distances, narrow angles, and multi-rebound shots.
    private func scoreEaseOfExecution(
        candidate: ShotGenerator.CandidateShot
    ) -> Double {
        // Difficulty factor from shot type
        let typePenalty = 1.0 / candidate.shotType.difficultyFactor
        
        // Distance penalty: longer shots are harder
        let totalPathLength = pathLength(candidate.strikerPath)
        let maxPath = CGFloat(BoardConfig.playingAreaDimension) * 2.0
        let distanceFactor = max(0, 1.0 - Double(totalPathLength / maxPath))
        
        return typePenalty * 0.6 + distanceFactor * 0.4
    }
    
    /// Future position: quality of the board state after the shot.
    private func scoreFuturePosition(
        simResult: PhysicsEngine.SimulationResult,
        playerColor: PlayerColor
    ) -> Double {
        // Good: player coins are spread out (not clustered)
        // Good: coins are near pockets
        // Bad: coins are in the center (hard to pocket)
        
        let playerBodies = simResult.finalBodies.filter {
            !$0.isPocketed && !$0.isStriker &&
            ($0.bodyType == playerColor.detectionType)
        }
        
        guard !playerBodies.isEmpty else { return 1.0 }  // All pocketed = great
        
        var score: Double = 0.5  // Neutral baseline
        
        // Bonus for coins near pockets
        let pocketCenters = PhysicsConstants.pocketCenters
        for body in playerBodies {
            let minDistToPocket = pocketCenters.map { body.position.distance(to: $0) }.min() ?? 999
            let normalizedDist = Double(minDistToPocket) / Double(BoardConfig.playingAreaDimension)
            score += (1.0 - normalizedDist) * 0.1
        }
        
        return min(1.0, max(0.0, score))
    }
    
    /// Queen opportunity: does this shot involve pocketing the queen?
    private func scoreQueenOpportunity(
        candidate: ShotGenerator.CandidateShot,
        simResult: PhysicsEngine.SimulationResult,
        matchState: MatchState
    ) -> Double {
        guard matchState.queenStatus == .onBoard else { return 0.5 }
        
        // If targeting the queen directly, high score
        if candidate.targetCoin.isQueen {
            let queenPocketed = simResult.pocketedBodies.contains { $0.bodyID == "queen" }
            return queenPocketed ? 1.0 : 0.3
        }
        
        // If the queen gets pocketed as a side effect, bonus
        let queenPocketed = simResult.pocketedBodies.contains { $0.bodyID == "queen" }
        return queenPocketed ? 0.8 : 0.5
    }
    
    /// Cover opportunity: can we cover the queen (pocket a player coin right after pocketing queen)?
    private func scoreCoverOpportunity(
        candidate: ShotGenerator.CandidateShot,
        simResult: PhysicsEngine.SimulationResult,
        matchState: MatchState
    ) -> Double {
        // Only relevant if queen needs covering
        guard matchState.queenStatus == .pocketed else { return 0.5 }
        
        // If we pocket a player coin, we cover the queen
        let playerCoinPocketed = simResult.pocketedBodies.contains {
            let type = simResult.finalBodies.first(where: { body in body.id == $0.bodyID })?.bodyType
            return type == matchState.playerColor.detectionType
        }
        
        return playerCoinPocketed ? 1.0 : 0.0
    }
    
    /// Foul risk: probability of pocketing the striker.
    /// Higher score = LOWER risk (inverted so high is always better).
    private func scoreFoulRisk(
        simResult: PhysicsEngine.SimulationResult
    ) -> Double {
        // If striker is pocketed, score is 0 (worst)
        return simResult.strikerPocketed ? 0.0 : 1.0
    }
    
    /// Unblock potential: does this shot break up coin clusters?
    private func scoreUnblockPotential(
        simResult: PhysicsEngine.SimulationResult,
        board: Board,
        playerColor: PlayerColor
    ) -> Double {
        // Compare clustering before and after
        let beforeCluster = clusterScore(coins: board.playerCoins(for: playerColor))
        
        let afterCoins = simResult.finalBodies.filter {
            !$0.isPocketed && !$0.isStriker &&
            $0.bodyType == playerColor.detectionType
        }
        let afterPositions = afterCoins.map { Coin(id: $0.id, coinType: $0.bodyType, position: $0.position) }
        let afterCluster = clusterScore(coins: afterPositions)
        
        // If clustering decreased (coins spread out), that's good
        if beforeCluster > 0 {
            let improvement = max(0, beforeCluster - afterCluster) / beforeCluster
            return 0.5 + improvement * 0.5
        }
        return 0.5
    }
    
    /// Opponent advantage: does this shot leave easy shots for the opponent?
    /// Higher score = opponent has FEWER easy shots (inverted).
    private func scoreOpponentAdvantage(
        simResult: PhysicsEngine.SimulationResult,
        board: Board,
        playerColor: PlayerColor
    ) -> Double {
        let opponentColor = playerColor.opponent
        
        // Count opponent coins near pockets after the shot
        let opponentBodies = simResult.finalBodies.filter {
            !$0.isPocketed && !$0.isStriker &&
            $0.bodyType == opponentColor.detectionType
        }
        
        let pocketCenters = PhysicsConstants.pocketCenters
        let nearPocketThreshold: CGFloat = 100.0  // mm
        
        var nearPocketCount = 0
        for body in opponentBodies {
            let minDist = pocketCenters.map { body.position.distance(to: $0) }.min() ?? 999
            if minDist < nearPocketThreshold {
                nearPocketCount += 1
            }
        }
        
        // Fewer opponent coins near pockets = better
        let maxCoins = Double(BoardConfig.blackCoinCount)
        return 1.0 - (Double(nearPocketCount) / maxCoins)
    }
    
    // MARK: - Utilities
    
    /// Calculate the total length of a path (sum of segment lengths).
    private func pathLength(_ path: [CGPoint]) -> CGFloat {
        guard path.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<path.count {
            total += path[i - 1].distance(to: path[i])
        }
        return total
    }
    
    /// Calculate a clustering score: average inverse-distance between coin pairs.
    /// Higher values = more clustered.
    private func clusterScore(coins: [Coin]) -> Double {
        guard coins.count > 1 else { return 0 }
        var totalInvDist: Double = 0
        var pairs = 0
        
        for i in 0..<(coins.count - 1) {
            for j in (i + 1)..<coins.count {
                let dist = Double(coins[i].position.distance(to: coins[j].position))
                if dist > 1 {
                    totalInvDist += 1.0 / dist
                }
                pairs += 1
            }
        }
        
        return pairs > 0 ? totalInvDist / Double(pairs) : 0
    }
}
