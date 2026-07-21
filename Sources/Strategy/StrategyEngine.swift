import Foundation
import CoreGraphics

// MARK: - Strategy Engine
/// Orchestrates shot generation, evaluation, and ranking to produce
/// the single best recommendation for the player.

public final class StrategyEngine: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let shotGenerator: ShotGenerator
    private let shotEvaluator: ShotEvaluator
    private let maxAnalysisTime: TimeInterval
    
    // MARK: - Initialization
    
    public init(
        shotGenerator: ShotGenerator = ShotGenerator(),
        shotEvaluator: ShotEvaluator = ShotEvaluator(),
        maxAnalysisTime: TimeInterval = AppConfig.maxAnalysisTimeSeconds
    ) {
        self.shotGenerator = shotGenerator
        self.shotEvaluator = shotEvaluator
        self.maxAnalysisTime = maxAnalysisTime
    }
    
    // MARK: - Analysis
    
    /// Analyze the current board state and return the best shot recommendation.
    ///
    /// - Parameters:
    ///   - board: Current board state with detected coins.
    ///   - matchState: Current match state.
    /// - Returns: The analysis result with the best shot, or nil if no viable shots exist.
    public func analyze(
        board: Board,
        matchState: MatchState
    ) -> AnalysisResult? {
        let startTime = Date()
        
        // Determine if queen should be targeted
        let includeQueen = shouldTargetQueen(matchState: matchState, board: board)
        
        // 1. Generate all candidate shots
        let candidates = shotGenerator.generateCandidates(
            board: board,
            playerColor: matchState.playerColor,
            includeQueen: includeQueen
        )
        
        Log.strategy.info("Generated \(candidates.count) candidate shots")
        
        guard !candidates.isEmpty else {
            Log.strategy.warning("No candidate shots generated")
            return nil
        }
        
        // 2. Evaluate each candidate (with time budget)
        var evaluatedShots: [ShotEvaluator.EvaluatedShot] = []
        
        for candidate in candidates {
            // Check time budget
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= maxAnalysisTime {
                Log.strategy.info("Time budget exhausted after evaluating \(evaluatedShots.count) shots")
                break
            }
            
            let evaluated = shotEvaluator.evaluate(
                candidate: candidate,
                board: board,
                playerColor: matchState.playerColor,
                matchState: matchState
            )
            evaluatedShots.append(evaluated)
        }
        
        guard !evaluatedShots.isEmpty else {
            Log.strategy.warning("No shots evaluated within time budget")
            return nil
        }
        
        // 3. Rank by composite score and select the best
        evaluatedShots.sort { $0.compositeScore > $1.compositeScore }
        
        let best = evaluatedShots[0]
        let analysisTime = Date().timeIntervalSince(startTime)
        
        // 4. Collect all pocketable coins
        let pocketableCoins = collectPocketableCoins(from: evaluatedShots)
        
        // 5. Generate reasoning text
        let reasoning = generateReasoning(
            best: best,
            totalCandidates: candidates.count,
            evaluatedCount: evaluatedShots.count
        )
        
        Log.strategy.info(
            "Best shot: \(best.candidate.shotType.rawValue) to \(best.candidate.targetPocket.rawValue) score=\(best.compositeScore) in \(analysisTime)s"
        )
        
        return AnalysisResult(
            bestShot: best,
            pocketableCoins: pocketableCoins,
            reasoning: reasoning,
            analysisTime: analysisTime,
            totalCandidates: candidates.count,
            evaluatedCandidates: evaluatedShots.count
        )
    }
    
    // MARK: - Queen Targeting Logic
    
    /// Determine if the queen should be targeted this turn.
    private func shouldTargetQueen(matchState: MatchState, board: Board) -> Bool {
        switch matchState.queenStatus {
        case .onBoard:
            // Target queen if player has enough coins to cover it afterwards
            return matchState.remainingPlayerCoins >= 2
        case .pocketed, .returned:
            // Queen already pocketed or returned — focus on covering or regular play
            return false
        case .covered:
            return false
        }
    }
    
    // MARK: - Pocketable Coins
    
    /// Collect unique coins that were successfully pocketed in any evaluated shot.
    private func collectPocketableCoins(
        from evaluatedShots: [ShotEvaluator.EvaluatedShot]
    ) -> [PocketableCoin] {
        var seen = Set<String>()
        var pocketable: [PocketableCoin] = []
        
        for shot in evaluatedShots {
            let targetPocketed = shot.simulationResult.pocketedBodies.contains {
                $0.bodyID == shot.candidate.targetCoin.id
            }
            
            if targetPocketed {
                let key = "\(shot.candidate.targetCoin.id)_\(shot.candidate.targetPocket.rawValue)"
                if !seen.contains(key) {
                    seen.insert(key)
                    pocketable.append(PocketableCoin(
                        coin: shot.candidate.targetCoin,
                        targetPocket: shot.candidate.targetPocket,
                        probability: shot.scores.pocketProbability,
                        shotType: shot.candidate.shotType
                    ))
                }
            }
        }
        
        return pocketable.sorted { $0.probability > $1.probability }
    }
    
    // MARK: - Reasoning
    
    /// Generate a human-readable explanation for the recommendation.
    private func generateReasoning(
        best: ShotEvaluator.EvaluatedShot,
        totalCandidates: Int,
        evaluatedCount: Int
    ) -> String {
        let candidate = best.candidate
        let scores = best.scores
        
        var parts: [String] = []
        
        // Shot type description
        parts.append("\(candidate.shotType.displayName) shot")
        
        // Target description
        parts.append("targeting \(candidate.targetCoin.coinType.displayName) coin")
        parts.append("to \(candidate.targetPocket.displayName) pocket")
        
        // Probability
        parts.append("(\(Int(scores.pocketProbability * 100))% success)")
        
        // Key factors
        if scores.foulRisk < 0.5 {
            parts.append("— watch for foul risk")
        }
        if scores.queenOpportunity > 0.7 {
            parts.append("— queen opportunity!")
        }
        
        // Stats
        parts.append("[\(evaluatedCount)/\(totalCandidates) shots analyzed]")
        
        return parts.joined(separator: " ")
    }
}

// MARK: - Analysis Result

extension StrategyEngine {
    
    /// The complete result of a strategic analysis.
    public struct AnalysisResult: Sendable {
        /// The highest-ranked evaluated shot.
        public let bestShot: ShotEvaluator.EvaluatedShot
        
        /// All coins that can be pocketed from the current board state.
        public let pocketableCoins: [PocketableCoin]
        
        /// Human-readable reasoning for the recommendation.
        public let reasoning: String
        
        /// Total analysis time in seconds.
        public let analysisTime: TimeInterval
        
        /// Total number of candidate shots generated.
        public let totalCandidates: Int
        
        /// Number of candidates that were evaluated within the time budget.
        public let evaluatedCandidates: Int
    }
}
