import Foundation

// MARK: - Application Constants
/// App-wide constants that don't belong to a specific configuration domain.

public enum AppConstants {
    
    /// Application name.
    public static let appName = "Carrom AI Coach"
    
    /// Application version.
    public static let appVersion = "1.0.0"
    
    /// Target device.
    public static let targetDevice = "iPhone 15 Plus"
    
    // MARK: - Database
    
    /// SQLite database filename.
    public static let databaseFilename = "carrom_coach.sqlite"
    
    /// Database schema version for migrations.
    public static let databaseSchemaVersion: Int = 1
    
    // MARK: - Coordinate System
    
    /// Normalized coordinate range minimum.
    public static let normalizedMin: Double = 0.0
    
    /// Normalized coordinate range maximum.
    public static let normalizedMax: Double = 1.0
    
    /// Origin of the board coordinate system in mm (center of playing area).
    public static let boardOriginX: Double = 0.0
    public static let boardOriginY: Double = 0.0
    
    // MARK: - Angles
    
    /// Full circle in radians.
    public static let fullCircle: Double = 2.0 * .pi
    
    /// Angular step for shot search (radians).
    /// 1 degree resolution = π/180.
    public static let angularStepRadians: Double = .pi / 180.0
    
    // MARK: - Shot Types
    
    /// Maximum number of cushion rebounds to evaluate.
    public static let maxRebounds: Int = 2
    
    // MARK: - Colors (RGBA for overlay rendering)
    
    /// Striker path color (green).
    public static let strikerPathColor = (r: 0.2, g: 0.9, b: 0.3, a: 0.8)
    
    /// Target coin path color (yellow).
    public static let targetPathColor = (r: 1.0, g: 0.9, b: 0.1, a: 0.8)
    
    /// Target coin highlight color.
    public static let targetCoinHighlightColor = (r: 1.0, g: 0.4, b: 0.1, a: 0.9)
    
    /// Target pocket highlight color.
    public static let targetPocketHighlightColor = (r: 0.1, g: 0.6, b: 1.0, a: 0.9)
    
    /// Striker placement marker color.
    public static let strikerMarkerColor = (r: 0.9, g: 0.2, b: 0.9, a: 0.9)
}
