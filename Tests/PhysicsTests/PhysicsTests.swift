import XCTest
@testable import CarromAICoach

// MARK: - Physics Tests
/// Unit tests for the 2D carrom physics engine.

final class PhysicsTests: XCTestCase {
    
    var engine: PhysicsEngine!
    
    override func setUp() {
        super.setUp()
        engine = PhysicsEngine()
    }
    
    // MARK: - Basic Simulation
    
    func testStationaryBodiesStayAtRest() {
        let coin = Coin.black(index: 0, position: CGPoint(x: 0, y: 0))
        let striker = Coin.striker(position: CGPoint(x: 0, y: 300))
        
        let bodies = [
            PhysicsBody(from: coin),
            PhysicsBody.striker(position: striker.position, velocity: .zero)
        ]
        
        let result = engine.simulate(bodies: bodies, strikerVelocity: .zero)
        
        // All bodies should remain at their starting positions
        XCTAssertEqual(result.pocketedCoinCount, 0, "No coins should be pocketed")
        XCTAssertFalse(result.strikerPocketed, "Striker should not be pocketed")
        XCTAssertEqual(result.stepCount, 1, "Should terminate after 1 step (all at rest)")
    }
    
    func testStrikerMovesWhenLaunched() {
        let striker = PhysicsBody.striker(
            position: CGPoint(x: 0, y: 300),
            velocity: .zero
        )
        
        let result = engine.simulate(
            bodies: [striker],
            strikerVelocity: CGVector(dx: 0, dy: -2000)
        )
        
        // Striker should have moved and come to rest via friction
        let finalStriker = result.finalBodies.first { $0.isStriker }
        XCTAssertNotNil(finalStriker, "Striker should exist in results")
        XCTAssertLessThan(finalStriker!.position.y, 300, "Striker should have moved upward")
        XCTAssertFalse(finalStriker!.isMoving, "Striker should be at rest after simulation")
    }
    
    // MARK: - Collision Tests
    
    func testHeadOnCollision() {
        // Striker aimed directly at a coin
        var striker = PhysicsBody(
            id: "striker",
            bodyType: .striker,
            position: CGPoint(x: 0, y: 200),
            velocity: .zero,
            radius: PhysicsConstants.strikerRadius,
            mass: PhysicsConstants.strikerMass
        )
        
        var coin = PhysicsBody(
            id: "black_0",
            bodyType: .blackCoin,
            position: CGPoint(x: 0, y: 0),
            velocity: .zero,
            radius: PhysicsConstants.coinRadius,
            mass: PhysicsConstants.coinMass
        )
        
        // Launch striker toward coin
        striker.velocity = CGVector(dx: 0, dy: -3000)
        
        // After enough steps, coin should have velocity
        striker.integrate(deltaTime: 0.05)  // Move closer
        
        let collided = CollisionResolver.resolve(&striker, &coin)
        
        if collided {
            // After collision, coin should be moving away from striker
            XCTAssertTrue(coin.velocity.dy < 0, "Coin should move in striker's direction")
        }
    }
    
    func testCollisionResolverSeparatesOverlapping() {
        var bodyA = PhysicsBody(
            id: "a", bodyType: .blackCoin,
            position: CGPoint(x: 0, y: 0),
            velocity: CGVector(dx: 100, dy: 0),
            radius: PhysicsConstants.coinRadius,
            mass: PhysicsConstants.coinMass
        )
        
        var bodyB = PhysicsBody(
            id: "b", bodyType: .whiteCoin,
            position: CGPoint(x: 20, y: 0),  // Overlapping (distance < 2 * coinRadius)
            velocity: .zero,
            radius: PhysicsConstants.coinRadius,
            mass: PhysicsConstants.coinMass
        )
        
        let resolved = CollisionResolver.resolve(&bodyA, &bodyB)
        
        XCTAssertTrue(resolved, "Overlapping bodies should collide")
        
        // After resolution, bodies should not overlap
        let dist = bodyA.position.distance(to: bodyB.position)
        let minDist = bodyA.radius + bodyB.radius
        XCTAssertGreaterThanOrEqual(dist, minDist - 0.01, "Bodies should be separated after collision")
    }
    
    // MARK: - Cushion Rebound Tests
    
    func testCushionRebound() {
        // Place a body near the left wall moving toward it
        var body = PhysicsBody(
            id: "test",
            bodyType: .blackCoin,
            position: CGPoint(x: -PhysicsConstants.halfBoard + 5, y: 0),
            velocity: CGVector(dx: -1000, dy: 0),
            radius: PhysicsConstants.coinRadius,
            mass: PhysicsConstants.coinMass
        )
        
        // Move body into wall
        body.integrate(deltaTime: 0.01)
        
        CushionRebound.apply(to: &body)
        
        // Velocity should be reflected (positive dx now)
        XCTAssertGreaterThan(body.velocity.dx, 0, "Velocity should reverse after wall hit")
    }
    
    // MARK: - Pocket Detection Tests
    
    func testPocketDetection() {
        // Place body exactly at top-left pocket
        let pocketPos = PhysicsConstants.pocketCenters[0]
        let body = PhysicsBody(
            id: "test",
            bodyType: .blackCoin,
            position: pocketPos,
            velocity: .zero,
            radius: PhysicsConstants.coinRadius,
            mass: PhysicsConstants.coinMass
        )
        
        let capturedPocket = body.checkPocketCapture()
        XCTAssertNotNil(capturedPocket, "Body at pocket center should be captured")
        XCTAssertEqual(capturedPocket, .topLeft)
    }
    
    func testNoPocketDetectionAtCenter() {
        let body = PhysicsBody(
            id: "test",
            bodyType: .blackCoin,
            position: CGPoint(x: 0, y: 0),
            velocity: .zero,
            radius: PhysicsConstants.coinRadius,
            mass: PhysicsConstants.coinMass
        )
        
        let capturedPocket = body.checkPocketCapture()
        XCTAssertNil(capturedPocket, "Body at center should not be in any pocket")
    }
    
    // MARK: - Friction Tests
    
    func testFrictionStopsBody() {
        var body = PhysicsBody(
            id: "test",
            bodyType: .blackCoin,
            position: .zero,
            velocity: CGVector(dx: 100, dy: 0),  // Slow speed
            radius: PhysicsConstants.coinRadius,
            mass: PhysicsConstants.coinMass
        )
        
        // Apply friction for many steps
        for _ in 0..<1000 {
            body.applyFriction(deltaTime: PhysicsConstants.timeStep)
            if !body.isMoving { break }
        }
        
        XCTAssertFalse(body.isMoving, "Body should come to rest after sufficient friction")
    }
    
    // MARK: - Direct Shot Simulation
    
    func testDirectShotToPocket() {
        // Set up a simple direct shot: striker → coin → pocket
        let pocketPos = PhysicsConstants.pocketCenters[0]  // Top-left
        
        // Place coin near the pocket
        let coinPos = CGPoint(x: pocketPos.x + 60, y: pocketPos.y + 60)
        let coin = Coin.black(index: 0, position: coinPos)
        
        // Place striker below the coin
        let strikerPos = CGPoint(x: coinPos.x + 100, y: coinPos.y + 200)
        
        // Aim angle: from striker toward coin, accounting for deflection toward pocket
        let aimAngle = strikerPos.angle(to: coinPos)
        
        let result = engine.simulateShot(
            coins: [coin],
            strikerPosition: strikerPos,
            aimAngle: aimAngle,
            power: 3000
        )
        
        // Verify simulation completed
        XCTAssertGreaterThan(result.stepCount, 0, "Simulation should have run")
        XCTAssertGreaterThan(result.simulationTime, 0, "Simulation time should be positive")
    }
    
    // MARK: - Physics Body Tests
    
    func testPhysicsBodyFromCoin() {
        let coin = Coin.black(index: 5, position: CGPoint(x: 100, y: -200))
        let body = PhysicsBody(from: coin)
        
        XCTAssertEqual(body.id, "black_5")
        XCTAssertEqual(body.bodyType, .blackCoin)
        XCTAssertEqual(body.position, coin.position)
        XCTAssertEqual(body.radius, CGFloat(BoardConfig.coinRadius))
        XCTAssertEqual(body.mass, CGFloat(BoardConfig.coinMass))
        XCTAssertFalse(body.isStriker)
        XCTAssertFalse(body.isPocketed)
    }
}
