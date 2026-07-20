import Foundation
import CoreGraphics

// MARK: - Simulatable Protocol
/// Protocol for objects that can participate in the 2D physics simulation.
/// Defines the physics interface for coins and the striker.

public protocol Simulatable: Identifiable, Sendable {
    
    /// Current position in board coordinates (millimeters from center).
    var position: CGPoint { get set }
    
    /// Current velocity in mm/s.
    var velocity: CGVector { get set }
    
    /// Radius of the physics body in millimeters.
    var bodyRadius: CGFloat { get }
    
    /// Mass of the body in grams.
    var bodyMass: CGFloat { get }
    
    /// Whether the body is currently in motion.
    var isMoving: Bool { get }
    
    /// Whether the body has been pocketed and removed from play.
    var isPocketed: Bool { get set }
    
    /// Apply a friction force to decelerate the body.
    /// - Parameter coefficient: Surface friction coefficient.
    /// - Parameter deltaTime: Time step in seconds.
    mutating func applyFriction(coefficient: CGFloat, deltaTime: CGFloat)
    
    /// Update position based on current velocity.
    /// - Parameter deltaTime: Time step in seconds.
    mutating func updatePosition(deltaTime: CGFloat)
}

// MARK: - Default Implementations

extension Simulatable {
    
    /// A body is considered moving if its velocity magnitude exceeds the rest threshold.
    public var isMoving: Bool {
        velocity.magnitudeSquared > CGFloat(AppConfig.restVelocityThreshold * AppConfig.restVelocityThreshold)
    }
    
    /// Apply kinetic friction to reduce velocity.
    public mutating func applyFriction(coefficient: CGFloat, deltaTime: CGFloat) {
        guard isMoving else {
            velocity = .zero
            return
        }
        
        let speed = velocity.magnitude
        // F_friction = μ * m * g, deceleration = μ * g
        let deceleration = coefficient * 9810.0  // g in mm/s² (9.81 m/s² = 9810 mm/s²)
        let newSpeed = max(0, speed - deceleration * deltaTime)
        
        if newSpeed <= CGFloat(AppConfig.restVelocityThreshold) {
            velocity = .zero
        } else {
            velocity = velocity.normalized * newSpeed
        }
    }
    
    /// Euler integration position update.
    public mutating func updatePosition(deltaTime: CGFloat) {
        guard isMoving else { return }
        position = CGPoint(
            x: position.x + velocity.dx * deltaTime,
            y: position.y + velocity.dy * deltaTime
        )
    }
}
