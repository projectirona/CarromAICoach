import Foundation

// MARK: - Application Configuration
/// Runtime-tunable application settings for camera, detection, and performance thresholds.

public struct AppConfig: Sendable {
    
    // MARK: - Camera Settings
    
    /// Minimum Laplacian variance to consider a frame non-blurry.
    /// Higher values = stricter blur rejection.
    public static let blurThreshold: Double = 100.0
    
    /// Number of consecutive stable frames required before auto-capture.
    /// A frame is "stable" if it differs minimally from the previous frame.
    public static let stableFrameCount: Int = 5
    
    /// Maximum pixel displacement between consecutive frames for stability.
    public static let stabilityDisplacementThreshold: Double = 5.0
    
    /// Camera resolution preset identifier.
    /// Corresponds to AVCaptureSession.Preset.
    public static let cameraPreset: String = "hd1920x1080"
    
    // MARK: - Detection Settings
    
    /// Minimum confidence score for coin detection (0.0 to 1.0).
    public static let coinDetectionConfidenceThreshold: Float = 0.5
    
    /// Minimum confidence for board rectangle detection.
    public static let boardDetectionConfidenceThreshold: Float = 0.8
    
    /// Non-maximum suppression IoU threshold for coin detection.
    public static let nmsIoUThreshold: Float = 0.5
    
    /// Maximum number of coins to detect in a single frame.
    /// 19 game coins + 1 striker = 20 max.
    public static let maxDetections: Int = 25
    
    // MARK: - Performance Settings
    
    /// Maximum allowed analysis time in seconds.
    /// If exceeded, the engine returns the best result found so far.
    public static let maxAnalysisTimeSeconds: Double = 1.0
    
    /// Maximum memory budget in MB.
    public static let maxMemoryBudgetMB: Int = 600
    
    /// Number of striker positions to sample along the baseline.
    public static let strikerSampleCount: Int = 50
    
    /// Physics simulation time step in seconds.
    public static let physicsTimeStep: Double = 0.001
    
    /// Maximum physics simulation duration in seconds.
    /// Prevents infinite loops if bodies don't reach rest.
    public static let maxSimulationDuration: Double = 5.0
    
    /// Velocity threshold below which a body is considered at rest (mm/s).
    public static let restVelocityThreshold: Double = 0.5
    
    // MARK: - UI Settings
    
    /// Duration for recommendation overlay fade-in animation (seconds).
    public static let overlayAnimationDuration: Double = 0.3
    
    /// Shot power display scale (1 to 10).
    public static let powerScaleMin: Int = 1
    public static let powerScaleMax: Int = 10
    
    private init() {}
}
