import Foundation
import CoreGraphics

// MARK: - Shot Model
/// Describes a complete shot recommendation: where to place the striker, where to aim, and how hard.

public struct Shot: Identifiable, Sendable, Codable, Equatable {
    
    /// Unique identifier for this shot.
    public let id: String
    
    /// Shot type classification.
    public let shotType: ShotType
    
    /// Striker placement position on the baseline (mm from center).
    public let strikerPosition: CGPoint
    
    /// Aim angle in radians from the positive x-axis.
    public let aimAngle: CGFloat
    
    /// Shot power as an impulse magnitude (mm/s initial velocity).
    public let power: CGFloat
    
    /// Normalized power for display (1 to 10 scale).
    public var displayPower: Int {
        let normalized = min(1.0, max(0.0, power / maxPower))
        return Int(normalized * CGFloat(AppConfig.powerScaleMax - AppConfig.powerScaleMin))
            + AppConfig.powerScaleMin
    }
    
    /// Maximum power value for normalization.
    private static let maxPowerValue: CGFloat = 5000.0
    private var maxPower: CGFloat { Shot.maxPowerValue }
    
    /// The target coin this shot aims to pocket.
    public let targetCoin: Coin
    
    /// The target pocket.
    public let targetPocket: PocketID
    
    /// Number of cushion rebounds in the shot path.
    public let rebounds: Int
    
    // MARK: - Path Geometry
    
    /// The path the striker travels (series of points in board mm coordinates).
    public let strikerPath: [CGPoint]
    
    /// The path the target coin travels to the pocket.
    public let coinPath: [CGPoint]
    
    // MARK: - Initialization
    
    public init(
        id: String = UUID().uuidString,
        shotType: ShotType,
        strikerPosition: CGPoint,
        aimAngle: CGFloat,
        power: CGFloat,
        targetCoin: Coin,
        targetPocket: PocketID,
        rebounds: Int,
        strikerPath: [CGPoint],
        coinPath: [CGPoint]
    ) {
        self.id = id
        self.shotType = shotType
        self.strikerPosition = strikerPosition
        self.aimAngle = aimAngle
        self.power = power
        self.targetCoin = targetCoin
        self.targetPocket = targetPocket
        self.rebounds = rebounds
        self.strikerPath = strikerPath
        self.coinPath = coinPath
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, shotType, strikerPositionX, strikerPositionY
        case aimAngle, power, targetCoin, targetPocket, rebounds
        case strikerPathX, strikerPathY, coinPathX, coinPathY
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        shotType = try container.decode(ShotType.self, forKey: .shotType)
        let sx = try container.decode(CGFloat.self, forKey: .strikerPositionX)
        let sy = try container.decode(CGFloat.self, forKey: .strikerPositionY)
        strikerPosition = CGPoint(x: sx, y: sy)
        aimAngle = try container.decode(CGFloat.self, forKey: .aimAngle)
        power = try container.decode(CGFloat.self, forKey: .power)
        targetCoin = try container.decode(Coin.self, forKey: .targetCoin)
        targetPocket = try container.decode(PocketID.self, forKey: .targetPocket)
        rebounds = try container.decode(Int.self, forKey: .rebounds)
        let spx = try container.decode([CGFloat].self, forKey: .strikerPathX)
        let spy = try container.decode([CGFloat].self, forKey: .strikerPathY)
        strikerPath = zip(spx, spy).map { CGPoint(x: $0, y: $1) }
        let cpx = try container.decode([CGFloat].self, forKey: .coinPathX)
        let cpy = try container.decode([CGFloat].self, forKey: .coinPathY)
        coinPath = zip(cpx, cpy).map { CGPoint(x: $0, y: $1) }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(shotType, forKey: .shotType)
        try container.encode(strikerPosition.x, forKey: .strikerPositionX)
        try container.encode(strikerPosition.y, forKey: .strikerPositionY)
        try container.encode(aimAngle, forKey: .aimAngle)
        try container.encode(power, forKey: .power)
        try container.encode(targetCoin, forKey: .targetCoin)
        try container.encode(targetPocket, forKey: .targetPocket)
        try container.encode(rebounds, forKey: .rebounds)
        try container.encode(strikerPath.map { $0.x }, forKey: .strikerPathX)
        try container.encode(strikerPath.map { $0.y }, forKey: .strikerPathY)
        try container.encode(coinPath.map { $0.x }, forKey: .coinPathX)
        try container.encode(coinPath.map { $0.y }, forKey: .coinPathY)
    }
}

// MARK: - Shot Type

/// Classification of shot complexity.
public enum ShotType: String, Sendable, CaseIterable, Codable {
    /// Direct striker-to-coin-to-pocket shot.
    case direct = "Direct"
    
    /// Shot using one cushion rebound.
    case singleRebound = "Single Rebound"
    
    /// Shot using two cushion rebounds.
    case doubleRebound = "Double Rebound"
    
    /// Display name.
    public var displayName: String { rawValue }
    
    /// Difficulty modifier (higher = harder).
    public var difficultyFactor: Double {
        switch self {
        case .direct: return 1.0
        case .singleRebound: return 1.5
        case .doubleRebound: return 2.5
        }
    }
}
