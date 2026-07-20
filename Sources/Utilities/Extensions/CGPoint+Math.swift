import Foundation
import CoreGraphics

// MARK: - CGPoint Math Extensions
/// Geometric and vector math operations on CGPoint for physics and strategy calculations.

extension CGPoint {
    
    // MARK: - Distance
    
    /// Euclidean distance to another point.
    public func distance(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Squared distance to another point (avoids sqrt for comparison).
    public func distanceSquared(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return dx * dx + dy * dy
    }
    
    // MARK: - Vector Arithmetic
    
    /// Add two points as vectors.
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    /// Subtract two points as vectors.
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    /// Scalar multiplication.
    public static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    /// Scalar multiplication (commutative).
    public static func * (scalar: CGFloat, point: CGPoint) -> CGPoint {
        point * scalar
    }
    
    /// Scalar division.
    public static func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
        guard scalar != 0 else { return .zero }
        return CGPoint(x: point.x / scalar, y: point.y / scalar)
    }
    
    // MARK: - Vector Operations
    
    /// Dot product with another point (treated as vectors from origin).
    public func dot(_ other: CGPoint) -> CGFloat {
        x * other.x + y * other.y
    }
    
    /// Cross product magnitude (z-component of 3D cross product).
    public func cross(_ other: CGPoint) -> CGFloat {
        x * other.y - y * other.x
    }
    
    /// Magnitude (length) of the vector from origin.
    public var magnitude: CGFloat {
        sqrt(x * x + y * y)
    }
    
    /// Squared magnitude (avoids sqrt).
    public var magnitudeSquared: CGFloat {
        x * x + y * y
    }
    
    /// Unit vector (normalized to length 1).
    public var normalized: CGPoint {
        let mag = magnitude
        guard mag > 0 else { return .zero }
        return self / mag
    }
    
    // MARK: - Angle
    
    /// Angle in radians from the positive x-axis (-π to π).
    public var angle: CGFloat {
        atan2(y, x)
    }
    
    /// Angle from this point to another point in radians.
    public func angle(to other: CGPoint) -> CGFloat {
        let delta = other - self
        return delta.angle
    }
    
    // MARK: - Transformations
    
    /// Rotate the point around the origin by the given angle in radians.
    public func rotated(by angle: CGFloat) -> CGPoint {
        let cosA = cos(angle)
        let sinA = sin(angle)
        return CGPoint(
            x: x * cosA - y * sinA,
            y: x * sinA + y * cosA
        )
    }
    
    /// Rotate the point around a given center by the given angle in radians.
    public func rotated(by angle: CGFloat, around center: CGPoint) -> CGPoint {
        let translated = self - center
        let rotated = translated.rotated(by: angle)
        return rotated + center
    }
    
    /// Reflect the point across a line defined by a normal vector through the origin.
    public func reflected(across normal: CGPoint) -> CGPoint {
        let n = normal.normalized
        let d = 2.0 * self.dot(n)
        return self - n * d
    }
    
    // MARK: - Interpolation
    
    /// Linear interpolation between this point and another.
    /// t = 0 returns self, t = 1 returns other.
    public func lerp(to other: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (other.x - x) * t,
            y: y + (other.y - y) * t
        )
    }
    
    // MARK: - Midpoint
    
    /// Midpoint between this point and another.
    public func midpoint(to other: CGPoint) -> CGPoint {
        lerp(to: other, t: 0.5)
    }
    
    // MARK: - Conversion
    
    /// Convert to CGVector.
    public var toVector: CGVector {
        CGVector(dx: x, dy: y)
    }
}
