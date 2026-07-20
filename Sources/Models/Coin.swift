import Foundation
import CoreGraphics

// MARK: - Coin Model
/// Represents a game piece on the carrom board: black coin, white coin, queen, or striker.

public struct Coin: Detectable, Simulatable, Codable, Equatable {
    
    /// Unique identifier for this coin.
    public let id: String
    
    /// Type of coin (black, white, queen, striker).
    public let coinType: DetectionType
    
    /// Current position in board coordinates (mm from center).
    public var position: CGPoint
    
    /// Current velocity in mm/s (used during physics simulation).
    public var velocity: CGVector
    
    /// Radius in millimeters.
    public let physicalRadius: CGFloat
    
    /// Mass in grams.
    public let mass: CGFloat
    
    /// Detection confidence score (0.0 to 1.0).
    public var confidence: Float
    
    /// Whether the coin is currently visible on the board.
    public var isVisible: Bool
    
    /// Whether the coin has been pocketed.
    public var isPocketed: Bool
    
    // MARK: - Detectable Conformance
    
    public var detectionType: DetectionType { coinType }
    
    public var radius: CGFloat { physicalRadius }
    
    // MARK: - Simulatable Conformance
    
    public var bodyRadius: CGFloat { physicalRadius }
    
    public var bodyMass: CGFloat { mass }
    
    // MARK: - Initialization
    
    /// Create a coin with full specification.
    public init(
        id: String,
        coinType: DetectionType,
        position: CGPoint,
        confidence: Float = 1.0,
        isVisible: Bool = true,
        isPocketed: Bool = false
    ) {
        self.id = id
        self.coinType = coinType
        self.position = position
        self.velocity = .zero
        self.physicalRadius = CGFloat(coinType.physicalRadiusMM)
        self.mass = CGFloat(coinType.physicalMassGrams)
        self.confidence = confidence
        self.isVisible = isVisible
        self.isPocketed = isPocketed
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, coinType, positionX, positionY, velocityDX, velocityDY
        case physicalRadius, mass, confidence, isVisible, isPocketed
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        coinType = try container.decode(DetectionType.self, forKey: .coinType)
        let px = try container.decode(CGFloat.self, forKey: .positionX)
        let py = try container.decode(CGFloat.self, forKey: .positionY)
        position = CGPoint(x: px, y: py)
        let vdx = try container.decode(CGFloat.self, forKey: .velocityDX)
        let vdy = try container.decode(CGFloat.self, forKey: .velocityDY)
        velocity = CGVector(dx: vdx, dy: vdy)
        physicalRadius = try container.decode(CGFloat.self, forKey: .physicalRadius)
        mass = try container.decode(CGFloat.self, forKey: .mass)
        confidence = try container.decode(Float.self, forKey: .confidence)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        isPocketed = try container.decode(Bool.self, forKey: .isPocketed)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coinType, forKey: .coinType)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(velocity.dx, forKey: .velocityDX)
        try container.encode(velocity.dy, forKey: .velocityDY)
        try container.encode(physicalRadius, forKey: .physicalRadius)
        try container.encode(mass, forKey: .mass)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(isPocketed, forKey: .isPocketed)
    }
}

// MARK: - Coin Factories

extension Coin {
    
    /// Create a black coin at the given position.
    public static func black(index: Int, position: CGPoint, confidence: Float = 1.0) -> Coin {
        Coin(id: "black_\(index)", coinType: .blackCoin, position: position, confidence: confidence)
    }
    
    /// Create a white coin at the given position.
    public static func white(index: Int, position: CGPoint, confidence: Float = 1.0) -> Coin {
        Coin(id: "white_\(index)", coinType: .whiteCoin, position: position, confidence: confidence)
    }
    
    /// Create the queen at the given position.
    public static func queen(position: CGPoint, confidence: Float = 1.0) -> Coin {
        Coin(id: "queen", coinType: .queen, position: position, confidence: confidence)
    }
    
    /// Create the striker at the given position.
    public static func striker(position: CGPoint) -> Coin {
        Coin(id: "striker", coinType: .striker, position: position, confidence: 1.0)
    }
}

// MARK: - Convenience

extension Coin {
    
    /// Whether this coin belongs to the given player color.
    public func belongsTo(playerColor: PlayerColor) -> Bool {
        switch playerColor {
        case .black: return coinType == .blackCoin
        case .white: return coinType == .whiteCoin
        }
    }
    
    /// Whether this is the queen.
    public var isQueen: Bool { coinType == .queen }
    
    /// Whether this is the striker.
    public var isStriker: Bool { coinType == .striker }
    
    /// Whether this is a game coin (not the striker).
    public var isGameCoin: Bool { coinType.isGameCoin }
    
    /// Whether this coin is still in play (visible, not pocketed).
    public var isInPlay: Bool { isVisible && !isPocketed }
}
