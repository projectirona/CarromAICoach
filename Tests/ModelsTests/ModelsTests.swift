import XCTest
@testable import CarromAICoach

// MARK: - Models Tests
/// Unit tests for all data models.

final class ModelsTests: XCTestCase {
    
    // MARK: - Coin Tests
    
    func testCoinFactories() {
        let black = Coin.black(index: 3, position: CGPoint(x: 100, y: -50))
        XCTAssertEqual(black.id, "black_3")
        XCTAssertEqual(black.coinType, .blackCoin)
        XCTAssertTrue(black.isGameCoin)
        XCTAssertFalse(black.isStriker)
        XCTAssertFalse(black.isQueen)
        XCTAssertTrue(black.isInPlay)
        
        let white = Coin.white(index: 0, position: .zero)
        XCTAssertEqual(white.id, "white_0")
        XCTAssertEqual(white.coinType, .whiteCoin)
        
        let queen = Coin.queen(position: CGPoint(x: 10, y: 20))
        XCTAssertEqual(queen.id, "queen")
        XCTAssertTrue(queen.isQueen)
        XCTAssertTrue(queen.isGameCoin)
        
        let striker = Coin.striker(position: CGPoint(x: 0, y: 300))
        XCTAssertEqual(striker.id, "striker")
        XCTAssertTrue(striker.isStriker)
        XCTAssertFalse(striker.isGameCoin)
    }
    
    func testCoinBelongsToPlayer() {
        let black = Coin.black(index: 0, position: .zero)
        let white = Coin.white(index: 0, position: .zero)
        
        XCTAssertTrue(black.belongsTo(playerColor: .black))
        XCTAssertFalse(black.belongsTo(playerColor: .white))
        XCTAssertTrue(white.belongsTo(playerColor: .white))
        XCTAssertFalse(white.belongsTo(playerColor: .black))
    }
    
    func testCoinCodable() throws {
        let original = Coin.black(index: 2, position: CGPoint(x: 123.4, y: -567.8), confidence: 0.95)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Coin.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.coinType, original.coinType)
        XCTAssertEqual(decoded.position.x, original.position.x, accuracy: 0.01)
        XCTAssertEqual(decoded.position.y, original.position.y, accuracy: 0.01)
        XCTAssertEqual(decoded.confidence, original.confidence, accuracy: 0.001)
    }
    
    // MARK: - Pocket Tests
    
    func testAllPocketsCreated() {
        let pockets = Pocket.allPockets()
        XCTAssertEqual(pockets.count, 4)
        
        let ids = Set(pockets.map { $0.id })
        XCTAssertTrue(ids.contains(.topLeft))
        XCTAssertTrue(ids.contains(.topRight))
        XCTAssertTrue(ids.contains(.bottomLeft))
        XCTAssertTrue(ids.contains(.bottomRight))
    }
    
    func testPocketPositionsAreCorners() {
        let pockets = Pocket.allPockets()
        let halfArea = CGFloat(BoardConfig.halfPlayingArea)
        
        for pocket in pockets {
            XCTAssertEqual(abs(pocket.positionMM.x), halfArea, accuracy: 0.1,
                           "Pocket \(pocket.id) X should be at board edge")
            XCTAssertEqual(abs(pocket.positionMM.y), halfArea, accuracy: 0.1,
                           "Pocket \(pocket.id) Y should be at board edge")
        }
    }
    
    // MARK: - Board Tests
    
    func testBoardEmpty() {
        let board = Board.empty()
        XCTAssertEqual(board.coins.count, 0)
        XCTAssertNil(board.striker)
        XCTAssertNil(board.queen)
        XCTAssertEqual(board.activeCoinCount, 0)
        XCTAssertFalse(board.isQueenOnBoard)
    }
    
    func testBoardQueries() {
        var board = Board.empty()
        board.coins = [
            .black(index: 0, position: .zero),
            .black(index: 1, position: CGPoint(x: 100, y: 0)),
            .white(index: 0, position: CGPoint(x: -100, y: 0)),
            .queen(position: CGPoint(x: 0, y: -100))
        ]
        
        XCTAssertEqual(board.playerCoins(for: .black).count, 2)
        XCTAssertEqual(board.playerCoins(for: .white).count, 1)
        XCTAssertEqual(board.remainingCount(for: .black), 2)
        XCTAssertTrue(board.isQueenOnBoard)
        XCTAssertEqual(board.activeCoinCount, 4)
    }
    
    func testBoardBoundsCheck() {
        let board = Board.empty()
        
        XCTAssertTrue(board.isWithinBounds(CGPoint(x: 0, y: 0)))
        XCTAssertTrue(board.isWithinBounds(CGPoint(x: 300, y: 300)))
        XCTAssertFalse(board.isWithinBounds(CGPoint(x: 500, y: 0)))
    }
    
    // MARK: - Match State Tests
    
    func testMatchStateInitialization() {
        let match = MatchState(playerColor: .black)
        
        XCTAssertEqual(match.playerColor, .black)
        XCTAssertEqual(match.currentTurn, 1)
        XCTAssertEqual(match.remainingPlayerCoins, 9)
        XCTAssertEqual(match.remainingOpponentCoins, 9)
        XCTAssertEqual(match.queenStatus, .onBoard)
        XCTAssertTrue(match.shotHistory.isEmpty)
    }
    
    func testMatchStateAdvanceTurn() {
        var match = MatchState(playerColor: .white)
        XCTAssertEqual(match.currentTurn, 1)
        
        match.advanceTurn()
        XCTAssertEqual(match.currentTurn, 2)
        
        match.advanceTurn()
        XCTAssertEqual(match.currentTurn, 3)
    }
    
    // MARK: - Player Color Tests
    
    func testPlayerColorOpponent() {
        XCTAssertEqual(PlayerColor.black.opponent, .white)
        XCTAssertEqual(PlayerColor.white.opponent, .black)
    }
    
    func testPlayerColorDetectionType() {
        XCTAssertEqual(PlayerColor.black.detectionType, .blackCoin)
        XCTAssertEqual(PlayerColor.white.detectionType, .whiteCoin)
    }
    
    // MARK: - Shot Tests
    
    func testShotDisplayPower() {
        let shot = Shot(
            shotType: .direct,
            strikerPosition: .zero,
            aimAngle: 0,
            power: 2500,  // 50% of max (5000)
            targetCoin: .black(index: 0, position: .zero),
            targetPocket: .topLeft,
            rebounds: 0,
            strikerPath: [.zero],
            coinPath: [.zero]
        )
        
        XCTAssertGreaterThanOrEqual(shot.displayPower, 1)
        XCTAssertLessThanOrEqual(shot.displayPower, 10)
    }
    
    // MARK: - Detection Type Tests
    
    func testDetectionTypeProperties() {
        XCTAssertTrue(DetectionType.blackCoin.isGameCoin)
        XCTAssertTrue(DetectionType.whiteCoin.isGameCoin)
        XCTAssertTrue(DetectionType.queen.isGameCoin)
        XCTAssertFalse(DetectionType.striker.isGameCoin)
        
        XCTAssertEqual(DetectionType.blackCoin.physicalRadiusMM, BoardConfig.coinRadius)
        XCTAssertEqual(DetectionType.striker.physicalRadiusMM, BoardConfig.strikerRadius)
    }
}
