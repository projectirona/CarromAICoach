import XCTest
@testable import CarromAICoach

// MARK: - Vision Tests
/// Unit tests for coordinate mapping and perspective correction.

final class VisionTests: XCTestCase {
    
    var mapper: CoordinateMapper!
    
    override func setUp() {
        super.setUp()
        mapper = CoordinateMapper(
            imageSize: CGSize(width: 800, height: 800),
            boardDimension: CGFloat(BoardConfig.playingAreaDimension)
        )
    }
    
    // MARK: - Coordinate Mapping Tests
    
    func testPixelToBoardCenter() {
        // Center pixel should map to board origin (0, 0)
        let boardPoint = mapper.pixelToBoard(CGPoint(x: 400, y: 400))
        XCTAssertEqual(boardPoint.x, 0, accuracy: 0.1, "Center pixel X should map to 0")
        XCTAssertEqual(boardPoint.y, 0, accuracy: 0.1, "Center pixel Y should map to 0")
    }
    
    func testBoardToPixelCenter() {
        // Board origin should map to center pixel
        let pixelPoint = mapper.boardToPixel(CGPoint(x: 0, y: 0))
        XCTAssertEqual(pixelPoint.x, 400, accuracy: 0.1, "Board origin X should map to center pixel")
        XCTAssertEqual(pixelPoint.y, 400, accuracy: 0.1, "Board origin Y should map to center pixel")
    }
    
    func testRoundTripPixelToBoard() {
        let originalPixel = CGPoint(x: 200, y: 600)
        let boardPoint = mapper.pixelToBoard(originalPixel)
        let backToPixel = mapper.boardToPixel(boardPoint)
        
        XCTAssertEqual(backToPixel.x, originalPixel.x, accuracy: 0.01,
                       "Round-trip pixel→board→pixel should preserve X")
        XCTAssertEqual(backToPixel.y, originalPixel.y, accuracy: 0.01,
                       "Round-trip pixel→board→pixel should preserve Y")
    }
    
    func testRoundTripBoardToPixel() {
        let originalBoard = CGPoint(x: -150, y: 200)
        let pixelPoint = mapper.boardToPixel(originalBoard)
        let backToBoard = mapper.pixelToBoard(pixelPoint)
        
        XCTAssertEqual(backToBoard.x, originalBoard.x, accuracy: 0.01,
                       "Round-trip board→pixel→board should preserve X")
        XCTAssertEqual(backToBoard.y, originalBoard.y, accuracy: 0.01,
                       "Round-trip board→pixel→board should preserve Y")
    }
    
    // MARK: - Normalized Coordinate Tests
    
    func testNormalizedCoordinates() {
        let topLeft = mapper.pixelToNormalized(CGPoint(x: 0, y: 0))
        XCTAssertEqual(topLeft.x, 0, accuracy: 0.001)
        XCTAssertEqual(topLeft.y, 0, accuracy: 0.001)
        
        let bottomRight = mapper.pixelToNormalized(CGPoint(x: 800, y: 800))
        XCTAssertEqual(bottomRight.x, 1, accuracy: 0.001)
        XCTAssertEqual(bottomRight.y, 1, accuracy: 0.001)
        
        let center = mapper.pixelToNormalized(CGPoint(x: 400, y: 400))
        XCTAssertEqual(center.x, 0.5, accuracy: 0.001)
        XCTAssertEqual(center.y, 0.5, accuracy: 0.001)
    }
    
    // MARK: - Distance Conversion Tests
    
    func testDistanceConversions() {
        let mm: CGFloat = 100
        let pixels = mapper.mmToPixels(mm)
        let backToMM = mapper.pixelsToMM(pixels)
        
        XCTAssertEqual(backToMM, mm, accuracy: 0.01,
                       "Round-trip mm→pixels→mm should preserve distance")
    }
    
    func testPixelsPerMMIsPositive() {
        XCTAssertGreaterThan(mapper.pixelsPerMM, 0, "Pixels per mm should be positive")
    }
    
    // MARK: - Bounds Checking Tests
    
    func testWithinBounds() {
        XCTAssertTrue(mapper.isWithinBounds(CGPoint(x: 0, y: 0)), "Center should be in bounds")
        XCTAssertTrue(mapper.isWithinBounds(CGPoint(x: 300, y: -300)), "Near corner should be in bounds")
    }
    
    func testOutOfBounds() {
        XCTAssertFalse(mapper.isWithinBounds(CGPoint(x: 500, y: 0)), "Far right should be out of bounds")
        XCTAssertFalse(mapper.isWithinBounds(CGPoint(x: 0, y: -500)), "Far top should be out of bounds")
    }
    
    func testClampToBounds() {
        let outsidePoint = CGPoint(x: 500, y: -600)
        let clamped = mapper.clampToBounds(outsidePoint)
        
        XCTAssertTrue(mapper.isWithinBounds(clamped), "Clamped point should be in bounds")
        XCTAssertEqual(clamped.x, mapper.boardDimensionMM / 2, accuracy: 0.01)
        XCTAssertEqual(clamped.y, -mapper.boardDimensionMM / 2, accuracy: 0.01)
    }
    
    // MARK: - CGPoint Extension Tests
    
    func testDistance() {
        let a = CGPoint(x: 0, y: 0)
        let b = CGPoint(x: 3, y: 4)
        XCTAssertEqual(a.distance(to: b), 5.0, accuracy: 0.001)
    }
    
    func testDotProduct() {
        let a = CGPoint(x: 1, y: 0)
        let b = CGPoint(x: 0, y: 1)
        XCTAssertEqual(a.dot(b), 0, accuracy: 0.001, "Perpendicular vectors have dot product 0")
        
        let c = CGPoint(x: 1, y: 0)
        let d = CGPoint(x: 1, y: 0)
        XCTAssertEqual(c.dot(d), 1, accuracy: 0.001, "Parallel unit vectors have dot product 1")
    }
    
    func testNormalized() {
        let v = CGPoint(x: 3, y: 4)
        let n = v.normalized
        XCTAssertEqual(n.magnitude, 1.0, accuracy: 0.001, "Normalized vector should have magnitude 1")
    }
    
    func testRotation() {
        let point = CGPoint(x: 1, y: 0)
        let rotated = point.rotated(by: .pi / 2)  // 90 degrees
        
        XCTAssertEqual(rotated.x, 0, accuracy: 0.001, "90° rotation of (1,0) should give x≈0")
        XCTAssertEqual(rotated.y, 1, accuracy: 0.001, "90° rotation of (1,0) should give y≈1")
    }
}
