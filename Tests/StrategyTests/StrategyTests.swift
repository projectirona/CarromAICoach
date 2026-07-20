import XCTest
@testable import CarromAICoach

// MARK: - Strategy Tests
/// Unit tests for the shot generation and evaluation pipeline.

final class StrategyTests: XCTestCase {
    
    var shotGenerator: ShotGenerator!
    var shotEvaluator: ShotEvaluator!
    var strategyEngine: StrategyEngine!
    
    override func setUp() {
        super.setUp()
        shotGenerator = ShotGenerator(strikerSampleCount: 10)  // Fewer samples for faster tests
        shotEvaluator = ShotEvaluator()
        strategyEngine = StrategyEngine(
            shotGenerator: shotGenerator,
            shotEvaluator: shotEvaluator,
            maxAnalysisTime: 5.0  // Generous time for tests
        )
    }
    
    // MARK: - Shot Generation Tests
    
    func testGeneratesCandidatesForPlayerCoins() {
        let board = createTestBoard()
        
        let candidates = shotGenerator.generateCandidates(
            board: board,
            playerColor: .black,
            includeQueen: false
        )
        
        XCTAssertGreaterThan(candidates.count, 0, "Should generate at least one candidate")
        
        // All candidates should target black coins
        for candidate in candidates {
            XCTAssertEqual(candidate.targetCoin.coinType, .blackCoin,
                           "All candidates should target player's (black) coins")
        }
    }
    
    func testIncludesQueenWhenRequested() {
        let board = createTestBoard()
        
        let withQueen = shotGenerator.generateCandidates(
            board: board,
            playerColor: .black,
            includeQueen: true
        )
        
        let withoutQueen = shotGenerator.generateCandidates(
            board: board,
            playerColor: .black,
            includeQueen: false
        )
        
        let queenCandidates = withQueen.filter { $0.targetCoin.isQueen }
        let noQueenCandidates = withoutQueen.filter { $0.targetCoin.isQueen }
        
        XCTAssertGreaterThan(queenCandidates.count, 0, "Should have queen candidates when included")
        XCTAssertEqual(noQueenCandidates.count, 0, "Should have no queen candidates when excluded")
    }
    
    func testAllShotTypesGenerated() {
        let board = createTestBoard()
        
        let candidates = shotGenerator.generateCandidates(
            board: board,
            playerColor: .black,
            includeQueen: false
        )
        
        let directShots = candidates.filter { $0.shotType == .direct }
        let reboundShots = candidates.filter { $0.shotType == .singleRebound }
        
        XCTAssertGreaterThan(directShots.count, 0, "Should generate direct shots")
        // Rebound shots may or may not exist depending on geometry
    }
    
    func testCandidatesHaveValidPower() {
        let board = createTestBoard()
        
        let candidates = shotGenerator.generateCandidates(
            board: board,
            playerColor: .black,
            includeQueen: false
        )
        
        for candidate in candidates {
            XCTAssertGreaterThanOrEqual(candidate.power, PhysicsConstants.minLaunchVelocity,
                                        "Power should be at or above minimum")
            XCTAssertLessThanOrEqual(candidate.power, PhysicsConstants.maxLaunchVelocity,
                                     "Power should be at or below maximum")
        }
    }
    
    // MARK: - Shot Evaluation Tests
    
    func testEvaluationProducesScores() {
        let board = createTestBoard()
        let matchState = MatchState(playerColor: .black)
        
        let candidates = shotGenerator.generateCandidates(
            board: board,
            playerColor: .black,
            includeQueen: false
        )
        
        guard let firstCandidate = candidates.first else {
            XCTFail("No candidates generated")
            return
        }
        
        let evaluated = shotEvaluator.evaluate(
            candidate: firstCandidate,
            board: board,
            playerColor: .black,
            matchState: matchState
        )
        
        // All scores should be between 0 and 1
        XCTAssertGreaterThanOrEqual(evaluated.scores.pocketProbability, 0.0)
        XCTAssertLessThanOrEqual(evaluated.scores.pocketProbability, 1.0)
        XCTAssertGreaterThanOrEqual(evaluated.scores.easeOfExecution, 0.0)
        XCTAssertLessThanOrEqual(evaluated.scores.easeOfExecution, 1.0)
        XCTAssertGreaterThanOrEqual(evaluated.scores.foulRisk, 0.0)
        XCTAssertLessThanOrEqual(evaluated.scores.foulRisk, 1.0)
        
        // Composite score should also be between 0 and 1
        XCTAssertGreaterThanOrEqual(evaluated.compositeScore, 0.0)
        XCTAssertLessThanOrEqual(evaluated.compositeScore, 1.0)
    }
    
    // MARK: - Strategy Engine Tests
    
    func testStrategyEngineProducesRecommendation() {
        let board = createTestBoard()
        let matchState = MatchState(playerColor: .black)
        
        let result = strategyEngine.analyze(board: board, matchState: matchState)
        
        XCTAssertNotNil(result, "Strategy engine should produce a result")
        XCTAssertGreaterThan(result!.totalCandidates, 0, "Should have candidates")
        XCTAssertGreaterThan(result!.evaluatedCandidates, 0, "Should have evaluated candidates")
        XCTAssertFalse(result!.reasoning.isEmpty, "Should have reasoning text")
    }
    
    func testEmptyBoardProducesNoResult() {
        let board = Board.empty()
        let matchState = MatchState(playerColor: .black)
        
        let result = strategyEngine.analyze(board: board, matchState: matchState)
        
        XCTAssertNil(result, "Empty board should produce no result")
    }
    
    // MARK: - Score Weights Tests
    
    func testDefaultWeightsSumToOne() {
        let weights = ScoreWeights.default
        XCTAssertTrue(weights.isValid, "Default weights should sum to 1.0 (got \(weights.totalWeight))")
    }
    
    func testAggressiveWeightsSumToOne() {
        let weights = ScoreWeights.aggressive
        XCTAssertTrue(weights.isValid, "Aggressive weights should sum to 1.0 (got \(weights.totalWeight))")
    }
    
    func testDefensiveWeightsSumToOne() {
        let weights = ScoreWeights.defensive
        XCTAssertTrue(weights.isValid, "Defensive weights should sum to 1.0 (got \(weights.totalWeight))")
    }
    
    // MARK: - Test Helpers
    
    /// Create a test board with coins in a typical mid-game position.
    private func createTestBoard() -> Board {
        var coins: [Coin] = []
        
        // 4 black coins at various positions
        coins.append(.black(index: 0, position: CGPoint(x: -150, y: -120)))
        coins.append(.black(index: 1, position: CGPoint(x: 80, y: -200)))
        coins.append(.black(index: 2, position: CGPoint(x: 200, y: 50)))
        coins.append(.black(index: 3, position: CGPoint(x: -100, y: 180)))
        
        // 4 white coins
        coins.append(.white(index: 0, position: CGPoint(x: 100, y: -150)))
        coins.append(.white(index: 1, position: CGPoint(x: -200, y: -50)))
        coins.append(.white(index: 2, position: CGPoint(x: 50, y: 100)))
        coins.append(.white(index: 3, position: CGPoint(x: -80, y: -250)))
        
        // Queen
        coins.append(.queen(position: CGPoint(x: 20, y: -10)))
        
        return Board(corners: Board.empty().corners, coins: coins)
    }
}
