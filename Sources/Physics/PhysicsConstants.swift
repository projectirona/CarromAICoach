import Foundation
import CoreGraphics

// MARK: - Physics Constants
/// All physical constants governing the carrom physics simulation.
/// Based on a standard 52-inch ICF carrom board with a 75mm striker.

public struct PhysicsConstants: Sendable {
    
    // MARK: - Board Dimensions (mm)
    
    /// Inner playing area half-width in mm.
    public static let halfBoard: CGFloat = CGFloat(BoardConfig.halfPlayingArea)
    
    /// Playing area bounds: min X.
    public static let minX: CGFloat = -halfBoard
    
    /// Playing area bounds: max X.
    public static let maxX: CGFloat = halfBoard
    
    /// Playing area bounds: min Y.
    public static let minY: CGFloat = -halfBoard
    
    /// Playing area bounds: max Y.
    public static let maxY: CGFloat = halfBoard
    
    // MARK: - Pocket Geometry
    
    /// Pocket capture radius in mm — coin is pocketed if center enters this radius.
    public static let pocketCaptureRadius: CGFloat = CGFloat(BoardConfig.pocketCaptureRadius)
    
    /// Pocket center positions in mm from board center.
    public static let pocketCenters: [CGPoint] = BoardConfig.pocketPositionsMM.map {
        CGPoint(x: $0.x, y: $0.y)
    }
    
    // MARK: - Friction
    
    /// Kinetic friction coefficient for a coin/striker sliding on the board surface.
    /// Lower values = more slippery (powdered board).
    public static let surfaceFriction: CGFloat = 0.15
    
    /// Rolling friction coefficient (slightly lower than sliding).
    public static let rollingFriction: CGFloat = 0.10
    
    // MARK: - Restitution (Bounciness)
    
    /// Coefficient of restitution for coin-coin collisions.
    /// 1.0 = perfectly elastic, 0.0 = perfectly inelastic.
    public static let coinCoinRestitution: CGFloat = 0.85
    
    /// Coefficient of restitution for coin-cushion (wall) collisions.
    public static let coinCushionRestitution: CGFloat = 0.70
    
    /// Coefficient of restitution for striker-coin collisions.
    /// Slightly higher than coin-coin due to heavier striker.
    public static let strikerCoinRestitution: CGFloat = 0.88
    
    // MARK: - Simulation Parameters
    
    /// Time step for physics integration (seconds).
    public static let timeStep: CGFloat = CGFloat(AppConfig.physicsTimeStep)
    
    /// Maximum simulation time before forced termination (seconds).
    public static let maxSimulationTime: CGFloat = CGFloat(AppConfig.maxSimulationDuration)
    
    /// Velocity magnitude threshold below which a body is considered at rest (mm/s).
    public static let restThreshold: CGFloat = CGFloat(AppConfig.restVelocityThreshold)
    
    /// Squared rest threshold (avoids sqrt in hot loop).
    public static let restThresholdSquared: CGFloat = restThreshold * restThreshold
    
    // MARK: - Gravity
    
    /// Gravitational acceleration in mm/s² (used for friction calculations).
    /// 9.81 m/s² = 9810 mm/s².
    public static let gravity: CGFloat = 9810.0
    
    // MARK: - Body Properties
    
    /// Coin radius in mm.
    public static let coinRadius: CGFloat = CGFloat(BoardConfig.coinRadius)
    
    /// Striker radius in mm.
    public static let strikerRadius: CGFloat = CGFloat(BoardConfig.strikerRadius)
    
    /// Coin mass in grams.
    public static let coinMass: CGFloat = CGFloat(BoardConfig.coinMass)
    
    /// Striker mass in grams.
    public static let strikerMass: CGFloat = CGFloat(BoardConfig.strikerMass)
    
    // MARK: - Power
    
    /// Minimum striker launch velocity in mm/s.
    public static let minLaunchVelocity: CGFloat = 500.0
    
    /// Maximum striker launch velocity in mm/s.
    public static let maxLaunchVelocity: CGFloat = 5000.0
    
    private init() {}
}
