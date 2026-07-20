import Foundation
import CoreGraphics

// MARK: - Physics Body
/// A circular rigid body in the 2D carrom physics simulation.
/// Represents coins and the striker during shot evaluation.

public struct PhysicsBody: Identifiable, Sendable {
    
    /// Unique identifier matching the originating Coin.id.
    public let id: String
    
    /// What type of piece this body represents.
    public let bodyType: DetectionType
    
    /// Center position in mm from board center.
    public var position: CGPoint
    
    /// Velocity in mm/s.
    public var velocity: CGVector
    
    /// Radius in mm.
    public let radius: CGFloat
    
    /// Mass in grams.
    public let mass: CGFloat
    
    /// Inverse mass (precomputed for collision response).
    public let inverseMass: CGFloat
    
    /// Whether this body has been captured by a pocket.
    public var isPocketed: Bool
    
    /// Which pocket captured this body (nil if not pocketed).
    public var pocketedIn: PocketID?
    
    // MARK: - Initialization
    
    /// Create a physics body from a Coin.
    public init(from coin: Coin) {
        self.id = coin.id
        self.bodyType = coin.coinType
        self.position = coin.position
        self.velocity = coin.velocity
        self.radius = coin.physicalRadius
        self.mass = coin.mass
        self.inverseMass = coin.mass > 0 ? 1.0 / coin.mass : 0.0
        self.isPocketed = coin.isPocketed
        self.pocketedIn = nil
    }
    
    /// Create a striker body at a given position with an initial velocity.
    public static func striker(position: CGPoint, velocity: CGVector) -> PhysicsBody {
        PhysicsBody(
            id: "striker",
            bodyType: .striker,
            position: position,
            velocity: velocity,
            radius: PhysicsConstants.strikerRadius,
            mass: PhysicsConstants.strikerMass
        )
    }
    
    /// General initializer.
    public init(
        id: String,
        bodyType: DetectionType,
        position: CGPoint,
        velocity: CGVector,
        radius: CGFloat,
        mass: CGFloat
    ) {
        self.id = id
        self.bodyType = bodyType
        self.position = position
        self.velocity = velocity
        self.radius = radius
        self.mass = mass
        self.inverseMass = mass > 0 ? 1.0 / mass : 0.0
        self.isPocketed = false
        self.pocketedIn = nil
    }
    
    // MARK: - State Queries
    
    /// Whether this body is in motion (velocity above rest threshold).
    public var isMoving: Bool {
        velocity.magnitudeSquared > PhysicsConstants.restThresholdSquared
    }
    
    /// Whether this body is the striker.
    public var isStriker: Bool {
        bodyType == .striker
    }
    
    /// Whether this body is still active in the simulation.
    public var isActive: Bool {
        !isPocketed
    }
    
    /// Speed in mm/s.
    public var speed: CGFloat {
        velocity.magnitude
    }
    
    // MARK: - Physics Updates
    
    /// Apply surface friction to decelerate the body.
    public mutating func applyFriction(deltaTime: CGFloat) {
        guard isMoving else {
            velocity = .zero
            return
        }
        
        let speed = self.speed
        let frictionDeceleration = PhysicsConstants.surfaceFriction * PhysicsConstants.gravity
        let newSpeed = max(0, speed - frictionDeceleration * deltaTime)
        
        if newSpeed <= PhysicsConstants.restThreshold {
            velocity = .zero
        } else {
            velocity = velocity.normalized * newSpeed
        }
    }
    
    /// Update position by integrating velocity over the time step.
    public mutating func integrate(deltaTime: CGFloat) {
        guard isMoving && isActive else { return }
        position = CGPoint(
            x: position.x + velocity.dx * deltaTime,
            y: position.y + velocity.dy * deltaTime
        )
    }
    
    /// Check if this body overlaps with another body.
    public func overlaps(with other: PhysicsBody) -> Bool {
        let minDist = radius + other.radius
        return position.distanceSquared(to: other.position) < minDist * minDist
    }
    
    /// Check if this body's center is within capture range of any pocket.
    /// Returns the pocket ID if captured, nil otherwise.
    public func checkPocketCapture() -> PocketID? {
        let captureRadiusSq = PhysicsConstants.pocketCaptureRadius * PhysicsConstants.pocketCaptureRadius
        
        for (index, pocketCenter) in PhysicsConstants.pocketCenters.enumerated() {
            if position.distanceSquared(to: pocketCenter) < captureRadiusSq {
                return PocketID.allCases[index]
            }
        }
        return nil
    }
}
