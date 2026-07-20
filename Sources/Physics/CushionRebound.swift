import Foundation
import CoreGraphics

// MARK: - Cushion Rebound
/// Handles wall (cushion) rebounds and pocket detection at board edges.

public struct CushionRebound: Sendable {
    
    /// Check if a body has gone beyond the board boundaries and apply cushion reflection.
    /// Also checks for pocket capture near corners.
    /// Returns the PocketID if the body was captured, nil otherwise.
    @discardableResult
    public static func apply(to body: inout PhysicsBody) -> PocketID? {
        guard body.isActive else { return nil }
        
        // First check pocket capture (corners are near boundaries)
        if let pocketID = body.checkPocketCapture() {
            body.isPocketed = true
            body.pocketedIn = pocketID
            body.velocity = .zero
            return pocketID
        }
        
        let halfBoard = PhysicsConstants.halfBoard
        let restitution = PhysicsConstants.coinCushionRestitution
        var bounced = false
        
        // Left wall
        if body.position.x - body.radius < -halfBoard {
            body.position = CGPoint(
                x: -halfBoard + body.radius,
                y: body.position.y
            )
            body.velocity = CGVector(
                dx: -body.velocity.dx * restitution,
                dy: body.velocity.dy
            )
            bounced = true
        }
        
        // Right wall
        if body.position.x + body.radius > halfBoard {
            body.position = CGPoint(
                x: halfBoard - body.radius,
                y: body.position.y
            )
            body.velocity = CGVector(
                dx: -body.velocity.dx * restitution,
                dy: body.velocity.dy
            )
            bounced = true
        }
        
        // Top wall
        if body.position.y - body.radius < -halfBoard {
            body.position = CGPoint(
                x: body.position.x,
                y: -halfBoard + body.radius
            )
            body.velocity = CGVector(
                dx: body.velocity.dx,
                dy: -body.velocity.dy * restitution
            )
            bounced = true
        }
        
        // Bottom wall
        if body.position.y + body.radius > halfBoard {
            body.position = CGPoint(
                x: body.position.x,
                y: halfBoard - body.radius
            )
            body.velocity = CGVector(
                dx: body.velocity.dx,
                dy: -body.velocity.dy * restitution
            )
            bounced = true
        }
        
        // After bouncing off a wall, check pocket capture again
        // (the body may have entered a pocket zone after rebound correction)
        if bounced {
            if let pocketID = body.checkPocketCapture() {
                body.isPocketed = true
                body.pocketedIn = pocketID
                body.velocity = .zero
                return pocketID
            }
        }
        
        return nil
    }
    
    /// Apply cushion checks to all active bodies.
    /// Returns a list of (bodyID, pocketID) pairs for bodies that were pocketed.
    public static func applyAll(_ bodies: inout [PhysicsBody]) -> [(String, PocketID)] {
        var pocketed: [(String, PocketID)] = []
        
        for i in 0..<bodies.count {
            guard bodies[i].isActive else { continue }
            if let pocketID = apply(to: &bodies[i]) {
                pocketed.append((bodies[i].id, pocketID))
            }
        }
        
        return pocketed
    }
}
