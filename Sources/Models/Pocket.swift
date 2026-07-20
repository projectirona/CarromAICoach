import Foundation
import CoreGraphics

// MARK: - Pocket Model
/// Represents one of the four corner pockets on the carrom board.

public struct Pocket: Identifiable, Sendable, Codable, Equatable {
    
    /// Unique pocket identifier.
    public let id: PocketID
    
    /// Position in board coordinates (millimeters from center of playing area).
    public let positionMM: CGPoint
    
    /// Position in normalized board coordinates (0.0 to 1.0).
    public let positionNormalized: CGPoint
    
    /// Physical pocket radius in millimeters.
    public let radius: CGFloat
    
    /// Capture radius — a coin is pocketed when its center is within this distance.
    public let captureRadius: CGFloat
    
    public init(id: PocketID) {
        self.id = id
        self.radius = CGFloat(BoardConfig.pocketRadius)
        self.captureRadius = CGFloat(BoardConfig.pocketCaptureRadius)
        
        let mmPos = BoardConfig.pocketPositionsMM[id.index]
        self.positionMM = CGPoint(x: mmPos.x, y: mmPos.y)
        
        let normPos = BoardConfig.pocketPositions[id.index]
        self.positionNormalized = CGPoint(x: normPos.x, y: normPos.y)
    }
}

// MARK: - Pocket Identification

/// Named identifiers for the four corner pockets.
public enum PocketID: String, Sendable, CaseIterable, Codable {
    case topLeft = "TL"
    case topRight = "TR"
    case bottomLeft = "BL"
    case bottomRight = "BR"
    
    /// Index into the pocket position arrays in BoardConfig.
    public var index: Int {
        switch self {
        case .topLeft: return 0
        case .topRight: return 1
        case .bottomLeft: return 2
        case .bottomRight: return 3
        }
    }
    
    /// Display name for UI.
    public var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
}

// MARK: - All Pockets Factory

extension Pocket {
    /// Create all four pockets.
    public static func allPockets() -> [Pocket] {
        PocketID.allCases.map { Pocket(id: $0) }
    }
}
