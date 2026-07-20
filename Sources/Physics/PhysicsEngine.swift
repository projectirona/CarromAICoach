import Foundation
import CoreGraphics

// MARK: - Physics Engine
/// Time-stepped 2D physics simulator for carrom shots.
/// Simulates striker launch, coin collisions, cushion rebounds, friction, and pocket captures.

public final class PhysicsEngine: @unchecked Sendable {
    
    // MARK: - Simulation Result
    
    /// The outcome of a physics simulation run.
    public struct SimulationResult: Sendable {
        /// Final positions of all bodies after simulation.
        public let finalBodies: [PhysicsBody]
        
        /// Bodies that were pocketed during the simulation, with their pocket IDs.
        public let pocketedBodies: [(bodyID: String, pocketID: PocketID)]
        
        /// Whether the striker was pocketed (foul).
        public let strikerPocketed: Bool
        
        /// Total simulation time in seconds.
        public let simulationTime: CGFloat
        
        /// Number of time steps executed.
        public let stepCount: Int
        
        /// IDs of pocketed coins (excluding striker).
        public var pocketedCoinIDs: [String] {
            pocketedBodies
                .filter { $0.bodyID != "striker" }
                .map { $0.bodyID }
        }
        
        /// Number of coins pocketed.
        public var pocketedCoinCount: Int {
            pocketedCoinIDs.count
        }
    }
    
    // MARK: - Properties
    
    /// Time step for integration.
    private let dt: CGFloat
    
    /// Maximum simulation duration.
    private let maxTime: CGFloat
    
    // MARK: - Initialization
    
    public init(
        timeStep: CGFloat = PhysicsConstants.timeStep,
        maxSimulationTime: CGFloat = PhysicsConstants.maxSimulationTime
    ) {
        self.dt = timeStep
        self.maxTime = maxSimulationTime
    }
    
    // MARK: - Simulation
    
    /// Run a complete physics simulation of a shot.
    ///
    /// - Parameters:
    ///   - bodies: All physics bodies on the board (coins + striker).
    ///   - strikerVelocity: Initial velocity to apply to the striker.
    /// - Returns: The simulation result with final positions and pocketed bodies.
    public func simulate(
        bodies: [PhysicsBody],
        strikerVelocity: CGVector
    ) -> SimulationResult {
        // Copy bodies for mutation
        var simBodies = bodies
        
        // Find and launch the striker
        if let strikerIndex = simBodies.firstIndex(where: { $0.isStriker }) {
            simBodies[strikerIndex].velocity = strikerVelocity
        }
        
        var pocketed: [(String, PocketID)] = []
        var elapsedTime: CGFloat = 0.0
        var stepCount = 0
        let maxSteps = Int(maxTime / dt)
        
        // Main simulation loop
        for _ in 0..<maxSteps {
            // 1. Integrate positions
            for i in 0..<simBodies.count {
                simBodies[i].integrate(deltaTime: dt)
            }
            
            // 2. Detect and resolve coin-coin collisions
            CollisionResolver.resolveAll(&simBodies)
            
            // 3. Detect and resolve cushion rebounds + pocket captures
            let newlyPocketed = CushionRebound.applyAll(&simBodies)
            pocketed.append(contentsOf: newlyPocketed)
            
            // 4. Apply friction
            for i in 0..<simBodies.count {
                simBodies[i].applyFriction(deltaTime: dt)
            }
            
            // 5. Check if all bodies are at rest
            elapsedTime += dt
            stepCount += 1
            
            let allAtRest = simBodies.allSatisfy { !$0.isMoving || !$0.isActive }
            if allAtRest {
                break
            }
        }
        
        let strikerPocketed = pocketed.contains { $0.0 == "striker" }
        
        return SimulationResult(
            finalBodies: simBodies,
            pocketedBodies: pocketed,
            strikerPocketed: strikerPocketed,
            simulationTime: elapsedTime,
            stepCount: stepCount
        )
    }
    
    // MARK: - Convenience
    
    /// Simulate a shot defined by striker position, aim angle, and power.
    ///
    /// - Parameters:
    ///   - coins: All coins currently on the board.
    ///   - strikerPosition: Where the striker is placed on the baseline (mm from center).
    ///   - aimAngle: Angle in radians from positive x-axis.
    ///   - power: Launch velocity magnitude in mm/s.
    /// - Returns: The simulation result.
    public func simulateShot(
        coins: [Coin],
        strikerPosition: CGPoint,
        aimAngle: CGFloat,
        power: CGFloat
    ) -> SimulationResult {
        // Create physics bodies from coins
        var bodies: [PhysicsBody] = coins
            .filter { $0.isInPlay && !$0.isStriker }
            .map { PhysicsBody(from: $0) }
        
        // Create striker body
        let striker = PhysicsBody.striker(position: strikerPosition, velocity: .zero)
        bodies.append(striker)
        
        // Calculate striker velocity from angle and power
        let velocity = CGVector.fromAngle(aimAngle, magnitude: power)
        
        return simulate(bodies: bodies, strikerVelocity: velocity)
    }
    
    /// Quick check: simulate a shot and return whether the target coin reaches the target pocket.
    public func doesShotPocket(
        coins: [Coin],
        strikerPosition: CGPoint,
        aimAngle: CGFloat,
        power: CGFloat,
        targetCoinID: String,
        targetPocket: PocketID
    ) -> (pocketed: Bool, result: SimulationResult) {
        let result = simulateShot(
            coins: coins,
            strikerPosition: strikerPosition,
            aimAngle: aimAngle,
            power: power
        )
        
        let targetPocketed = result.pocketedBodies.contains {
            $0.bodyID == targetCoinID && $0.pocketID == targetPocket
        }
        
        return (targetPocketed, result)
    }
}
