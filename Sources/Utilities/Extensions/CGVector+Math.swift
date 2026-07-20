import Foundation
import CoreGraphics

// MARK: - CGVector Math Extensions
/// Vector math operations on CGVector for physics impulse and velocity calculations.

extension CGVector {
    
    // MARK: - Magnitude
    
    /// Magnitude (length) of the vector.
    public var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }
    
    /// Squared magnitude (avoids sqrt for comparisons).
    public var magnitudeSquared: CGFloat {
        dx * dx + dy * dy
    }
    
    // MARK: - Normalization
    
    /// Unit vector (normalized to length 1).
    public var normalized: CGVector {
        let mag = magnitude
        guard mag > 0 else { return .zero }
        return CGVector(dx: dx / mag, dy: dy / mag)
    }
    
    // MARK: - Arithmetic
    
    /// Add two vectors.
    public static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
    
    /// Subtract two vectors.
    public static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }
    
    /// Scalar multiplication.
    public static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
        CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }
    
    /// Scalar multiplication (commutative).
    public static func * (scalar: CGFloat, vector: CGVector) -> CGVector {
        vector * scalar
    }
    
    /// Scalar division.
    public static func / (vector: CGVector, scalar: CGFloat) -> CGVector {
        guard scalar != 0 else { return .zero }
        return CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
    }
    
    /// Negate a vector.
    public static prefix func - (vector: CGVector) -> CGVector {
        CGVector(dx: -vector.dx, dy: -vector.dy)
    }
    
    // MARK: - Compound Assignment
    
    public static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs + rhs
    }
    
    public static func -= (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs - rhs
    }
    
    public static func *= (lhs: inout CGVector, scalar: CGFloat) {
        lhs = lhs * scalar
    }
    
    // MARK: - Dot Product
    
    /// Dot product with another vector.
    public func dot(_ other: CGVector) -> CGFloat {
        dx * other.dx + dy * other.dy
    }
    
    // MARK: - Angle
    
    /// Angle of the vector in radians from positive x-axis.
    public var angle: CGFloat {
        atan2(dy, dx)
    }
    
    // MARK: - Factory
    
    /// Create a unit vector from an angle in radians.
    public static func fromAngle(_ radians: CGFloat) -> CGVector {
        CGVector(dx: cos(radians), dy: sin(radians))
    }
    
    /// Create a vector with given magnitude and angle.
    public static func fromAngle(_ radians: CGFloat, magnitude: CGFloat) -> CGVector {
        CGVector(dx: cos(radians) * magnitude, dy: sin(radians) * magnitude)
    }
    
    // MARK: - Reflection
    
    /// Reflect this vector across a surface with the given normal.
    public func reflected(normal: CGVector) -> CGVector {
        let n = normal.normalized
        let d = 2.0 * self.dot(n)
        return self - n * d
    }
    
    // MARK: - Conversion
    
    /// Convert to CGPoint.
    public var toPoint: CGPoint {
        CGPoint(x: dx, y: dy)
    }
}
