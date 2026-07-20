import Foundation
import CoreGraphics

// MARK: - Detectable Protocol
/// Protocol for objects that can be detected in a camera frame by the vision system.
/// Adopted by coins, the striker, the queen, and board landmarks.

public protocol Detectable: Identifiable, Sendable {
    
    /// The type/class of the detected object.
    var detectionType: DetectionType { get }
    
    /// Position in normalized board coordinates (0.0 to 1.0).
    var position: CGPoint { get }
    
    /// Radius of the detected object in normalized coordinates.
    var radius: CGFloat { get }
    
    /// Confidence score of the detection (0.0 to 1.0).
    var confidence: Float { get }
    
    /// Whether the object is currently visible (not occluded or off-board).
    var isVisible: Bool { get }
}

// MARK: - Detection Type

/// Classification of detectable objects on the carrom board.
public enum DetectionType: String, Sendable, CaseIterable, Codable {
    case blackCoin = "black"
    case whiteCoin = "white"
    case queen = "queen"
    case striker = "striker"
    
    /// Display name for UI.
    public var displayName: String {
        switch self {
        case .blackCoin: return "Black"
        case .whiteCoin: return "White"
        case .queen: return "Queen"
        case .striker: return "Striker"
        }
    }
    
    /// Whether this type is a player coin (not striker).
    public var isGameCoin: Bool {
        switch self {
        case .blackCoin, .whiteCoin, .queen:
            return true
        case .striker:
            return false
        }
    }
    
    /// Physical radius in millimeters.
    public var physicalRadiusMM: Double {
        switch self {
        case .blackCoin, .whiteCoin, .queen:
            return BoardConfig.coinRadius
        case .striker:
            return BoardConfig.strikerRadius
        }
    }
    
    /// Physical mass in grams.
    public var physicalMassGrams: Double {
        switch self {
        case .blackCoin, .whiteCoin, .queen:
            return BoardConfig.coinMass
        case .striker:
            return BoardConfig.strikerMass
        }
    }
}
