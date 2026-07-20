import Foundation
import OSLog

// MARK: - Logger
/// Centralized logging facility using Apple's OSLog framework.
/// Provides category-based logging for all application subsystems.

public enum Log {
    
    /// The subsystem identifier for all CarromAICoach logs.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.carrom.aicoach"
    
    /// Camera module logger.
    public static let camera = Logger(subsystem: subsystem, category: "Camera")
    
    /// Board detection logger.
    public static let boardDetection = Logger(subsystem: subsystem, category: "BoardDetection")
    
    /// Coin detection logger.
    public static let coinDetection = Logger(subsystem: subsystem, category: "CoinDetection")
    
    /// Perspective correction and coordinate mapping logger.
    public static let vision = Logger(subsystem: subsystem, category: "Vision")
    
    /// Physics engine logger.
    public static let physics = Logger(subsystem: subsystem, category: "Physics")
    
    /// Strategy engine logger.
    public static let strategy = Logger(subsystem: subsystem, category: "Strategy")
    
    /// Recommendation engine logger.
    public static let recommendation = Logger(subsystem: subsystem, category: "Recommendation")
    
    /// Match state management logger.
    public static let matchState = Logger(subsystem: subsystem, category: "MatchState")
    
    /// Database operations logger.
    public static let database = Logger(subsystem: subsystem, category: "Database")
    
    /// UI and rendering logger.
    public static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// General application logger.
    public static let app = Logger(subsystem: subsystem, category: "App")
}
