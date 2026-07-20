import Foundation
import CoreGraphics

// MARK: - Collision Detection & Response
/// Handles elastic circle-circle collisions between carrom pieces.

public struct CollisionResolver: Sendable {
    
    /// Detect and resolve a collision between two physics bodies.
    /// Returns true if a collision was detected and resolved.
    @discardableResult
    public static func resolve(
        _ bodyA: inout PhysicsBody,
        _ bodyB: inout PhysicsBody
    ) -> Bool {
        guard bodyA.isActive && bodyB.isActive else { return false }
        
        // Check overlap
        let dx = bodyB.position.x - bodyA.position.x
        let dy = bodyB.position.y - bodyA.position.y
        let distSq = dx * dx + dy * dy
        let minDist = bodyA.radius + bodyB.radius
        
        guard distSq < minDist * minDist && distSq > 0.0001 else {
            return false
        }
        
        let dist = sqrt(distSq)
        
        // Collision normal (from A to B)
        let nx = dx / dist
        let ny = dy / dist
        
        // Separate overlapping bodies (push apart equally weighted by inverse mass)
        let overlap = minDist - dist
        let totalInvMass = bodyA.inverseMass + bodyB.inverseMass
        
        if totalInvMass > 0 {
            let separationA = overlap * (bodyA.inverseMass / totalInvMass)
            let separationB = overlap * (bodyB.inverseMass / totalInvMass)
            
            bodyA.position = CGPoint(
                x: bodyA.position.x - nx * separationA,
                y: bodyA.position.y - ny * separationA
            )
            bodyB.position = CGPoint(
                x: bodyB.position.x + nx * separationB,
                y: bodyB.position.y + ny * separationB
            )
        }
        
        // Relative velocity along collision normal
        let relVelX = bodyA.velocity.dx - bodyB.velocity.dx
        let relVelY = bodyA.velocity.dy - bodyB.velocity.dy
        let relVelDotNormal = relVelX * nx + relVelY * ny
        
        // Only resolve if bodies are approaching
        guard relVelDotNormal > 0 else { return false }
        
        // Determine restitution based on body types
        let restitution = Self.restitution(for: bodyA, and: bodyB)
        
        // Impulse magnitude (1D elastic collision formula)
        let impulseMagnitude = -(1.0 + restitution) * relVelDotNormal / totalInvMass
        
        // Apply impulse
        let impulseX = impulseMagnitude * nx
        let impulseY = impulseMagnitude * ny
        
        bodyA.velocity = CGVector(
            dx: bodyA.velocity.dx + impulseX * bodyA.inverseMass,
            dy: bodyA.velocity.dy + impulseY * bodyA.inverseMass
        )
        bodyB.velocity = CGVector(
            dx: bodyB.velocity.dx - impulseX * bodyB.inverseMass,
            dy: bodyB.velocity.dy - impulseY * bodyB.inverseMass
        )
        
        return true
    }
    
    /// Determine the coefficient of restitution based on the types of colliding bodies.
    private static func restitution(for a: PhysicsBody, and b: PhysicsBody) -> CGFloat {
        if a.isStriker || b.isStriker {
            return PhysicsConstants.strikerCoinRestitution
        }
        return PhysicsConstants.coinCoinRestitution
    }
    
    /// Check all pairs of bodies for collisions and resolve them.
    /// Performs a single pass (sufficient for carrom where multi-body pileups are rare).
    public static func resolveAll(_ bodies: inout [PhysicsBody]) {
        let count = bodies.count
        guard count > 1 else { return }
        
        for i in 0..<(count - 1) {
            for j in (i + 1)..<count {
                guard bodies[i].isActive && bodies[j].isActive else { continue }
                var bodyA = bodies[i]
                var bodyB = bodies[j]
                resolve(&bodyA, &bodyB)
                bodies[i] = bodyA
                bodies[j] = bodyB
            }
        }
    }
}
