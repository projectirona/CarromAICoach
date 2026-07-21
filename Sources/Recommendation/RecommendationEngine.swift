import Foundation
import UIKit

// MARK: - Recommendation Engine
/// Orchestrates the complete analysis pipeline:
/// Camera frame → Board detection → Perspective correction → Coin detection → Strategy → Recommendation

public final class RecommendationEngine: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let boardDetector: BoardDetector
    private let coinDetector: CoinDetector
    private let perspectiveCorrector: PerspectiveCorrector
    private let coordinateMapper: CoordinateMapper
    private let strategyEngine: StrategyEngine
    
    // MARK: - Initialization
    
    public init(
        boardDetector: BoardDetector = BoardDetector(),
        coinDetector: CoinDetector = CoinDetector(mode: .mock),
        perspectiveCorrector: PerspectiveCorrector = PerspectiveCorrector(),
        coordinateMapper: CoordinateMapper = CoordinateMapper(),
        strategyEngine: StrategyEngine = StrategyEngine()
    ) {
        self.boardDetector = boardDetector
        self.coinDetector = coinDetector
        self.perspectiveCorrector = perspectiveCorrector
        self.coordinateMapper = coordinateMapper
        self.strategyEngine = strategyEngine
    }
    
    // MARK: - Full Pipeline
    
    /// Run the complete analysis pipeline on a captured camera frame.
    ///
    /// - Parameters:
    ///   - image: The captured camera frame.
    ///   - matchState: Current match state.
    /// - Returns: A Recommendation, or nil if analysis fails.
    public func analyze(
        image: UIImage,
        matchState: MatchState
    ) async -> ARState? {
        let startTime = Date()
        
        Log.recommendation.info("Starting analysis pipeline")
        
        // 1. Detect board
        guard let boardResult = await boardDetector.detectBoard(in: image) else {
            Log.recommendation.error("Board detection failed")
            return nil
        }
        
        guard boardResult.isValid else {
            Log.recommendation.warning("Board detection confidence too low: \(boardResult.confidence)")
            return nil
        }
        
        // 2. Apply perspective correction
        guard let correctedImage = perspectiveCorrector.correct(
            image: image,
            corners: boardResult.corners
        ) else {
            Log.recommendation.error("Perspective correction failed")
            return nil
        }
        
        // 3. Detect coins
        let detectedCoins = await coinDetector.detectCoins(in: correctedImage)
        
        guard !detectedCoins.isEmpty else {
            Log.recommendation.warning("No coins detected")
            return nil
        }
        
        Log.recommendation.info("Detected \(detectedCoins.count) coins")
        
        // 4. Build board model
        let board = Board(
            corners: boardResult.corners,
            coins: detectedCoins,
            striker: nil  // Striker is not on the board during analysis
        )
        
        // 5. Run strategy engine
        guard let analysisResult = strategyEngine.analyze(
            board: board,
            matchState: matchState
        ) else {
            Log.recommendation.warning("Strategy engine found no viable shots")
            return nil
        }
        
        // 6. Build recommendation
        let bestCandidate = analysisResult.bestShot.candidate
        
        let shot = Shot(
            shotType: bestCandidate.shotType,
            strikerPosition: bestCandidate.strikerPosition,
            aimAngle: bestCandidate.aimAngle,
            power: bestCandidate.power,
            targetCoin: bestCandidate.targetCoin,
            targetPocket: bestCandidate.targetPocket,
            rebounds: bestCandidate.shotType == .direct ? 0 :
                      bestCandidate.shotType == .singleRebound ? 1 : 2,
            strikerPath: bestCandidate.strikerPath,
            coinPath: bestCandidate.coinPath
        )
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        let recommendation = Recommendation(
            shot: shot,
            probability: analysisResult.bestShot.scores.pocketProbability,
            pocketableCoins: analysisResult.pocketableCoins,
            reasoning: analysisResult.reasoning,
            boardSnapshot: board,
            analysisTime: totalTime
        )
        
        Log.recommendation.info(
            "Analysis complete in \(totalTime)s: \(shot.shotType.displayName) to \(shot.targetPocket.displayName) (\(recommendation.probabilityPercent))"
        )
        
        return ARState(recommendation: recommendation, boardObservation: boardResult.observation)
    }
}
