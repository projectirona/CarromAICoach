import Foundation
import CoreGraphics

// MARK: - Shot Generator
/// Enumerates all legal candidate shots for the current board state.
/// For each player coin × pocket combination, generates direct, single-rebound,
/// and double-rebound shot paths from sampled striker positions along the baseline.

public final class ShotGenerator: @unchecked Sendable {
    
    // MARK: - Candidate Shot
    
    /// A candidate shot to be evaluated by the ShotEvaluator.
    public struct CandidateShot: Sendable {
        public let strikerPosition: CGPoint
        public let aimAngle: CGFloat
        public let power: CGFloat
        public let targetCoin: Coin
        public let targetPocket: PocketID
        public let shotType: ShotType
        public let strikerPath: [CGPoint]
        public let coinPath: [CGPoint]
    }
    
    // MARK: - Properties
    
    private let sampleCount: Int
    private let pockets: [Pocket]
    
    // MARK: - Initialization
    
    public init(strikerSampleCount: Int = AppConfig.strikerSampleCount) {
        self.sampleCount = strikerSampleCount
        self.pockets = Pocket.allPockets()
    }
    
    // MARK: - Generation
    
    /// Generate all candidate shots for the given board state and player color.
    ///
    /// - Parameters:
    ///   - board: Current board state with detected coins.
    ///   - playerColor: The player's color (only their coins are targeted).
    ///   - includeQueen: Whether to include queen as a target.
    /// - Returns: Array of candidate shots to evaluate.
    public func generateCandidates(
        board: Board,
        playerColor: PlayerColor,
        includeQueen: Bool = true
    ) -> [CandidateShot] {
        var candidates: [CandidateShot] = []
        
        // Target coins: player's coins + optionally the queen
        var targetCoins = board.playerCoins(for: playerColor)
        if includeQueen, let queen = board.queen {
            targetCoins.append(queen)
        }
        
        guard !targetCoins.isEmpty else { return candidates }
        
        // Sample striker positions along the baseline
        let strikerPositions = sampleBaselinePositions()
        
        // All active coins for line-of-sight checks
        let allActiveCoins = board.activeCoins
        
        for targetCoin in targetCoins {
            for pocket in pockets {
                // Generate direct shots
                let directCandidates = generateDirectShots(
                    targetCoin: targetCoin,
                    pocket: pocket,
                    strikerPositions: strikerPositions,
                    allCoins: allActiveCoins
                )
                candidates.append(contentsOf: directCandidates)
                
                // Generate single-rebound shots
                let reboundCandidates = generateSingleReboundShots(
                    targetCoin: targetCoin,
                    pocket: pocket,
                    strikerPositions: strikerPositions,
                    allCoins: allActiveCoins
                )
                candidates.append(contentsOf: reboundCandidates)
            }
        }
        
        return candidates
    }
    
    // MARK: - Baseline Sampling
    
    /// Generate evenly-spaced striker positions along the baseline.
    private func sampleBaselinePositions() -> [CGPoint] {
        let minX = CGFloat(BoardConfig.baselineMinX)
        let maxX = CGFloat(BoardConfig.baselineMaxX)
        let baselineY = CGFloat(BoardConfig.baselineY)
        
        guard sampleCount > 1 else {
            return [CGPoint(x: 0, y: baselineY)]
        }
        
        let step = (maxX - minX) / CGFloat(sampleCount - 1)
        
        return (0..<sampleCount).map { i in
            CGPoint(x: minX + step * CGFloat(i), y: baselineY)
        }
    }
    
    // MARK: - Direct Shots
    
    /// Generate direct shot candidates: striker → coin → pocket.
    private func generateDirectShots(
        targetCoin: Coin,
        pocket: Pocket,
        strikerPositions: [CGPoint],
        allCoins: [Coin]
    ) -> [CandidateShot] {
        var shots: [CandidateShot] = []
        
        // Calculate where the striker must hit the target coin to send it toward the pocket
        let coinPos = targetCoin.position
        let pocketPos = pocket.positionMM
        
        // Direction from coin to pocket
        let coinToPocket = (pocketPos - coinPos).normalized
        
        // The striker must hit the coin from the opposite side of the pocket direction
        // Contact point on the target coin surface
        let contactOffset = coinToPocket * -(targetCoin.physicalRadius + CGFloat(BoardConfig.strikerRadius))
        let aimPoint = coinPos + contactOffset
        
        for strikerPos in strikerPositions {
            // Check if the striker can reach the aim point
            let strikerToAim = aimPoint - strikerPos
            let aimAngle = strikerToAim.angle
            let distance = strikerToAim.magnitude
            
            // Skip if the striker is too close or the angle is unreasonable
            guard distance > CGFloat(BoardConfig.strikerRadius) + targetCoin.physicalRadius else {
                continue
            }
            
            // Check line of sight from striker to target coin
            let hasLineOfSight = checkLineOfSight(
                from: strikerPos,
                to: aimPoint,
                excludingCoinID: targetCoin.id,
                strikerRadius: CGFloat(BoardConfig.strikerRadius),
                allCoins: allCoins
            )
            
            guard hasLineOfSight else { continue }
            
            // Estimate power needed based on distance and friction
            let power = estimatePower(
                strikerToContact: distance,
                coinToPocket: coinPos.distance(to: pocketPos)
            )
            
            let strikerPath = [strikerPos, aimPoint]
            let coinPath = [coinPos, pocketPos]
            
            shots.append(CandidateShot(
                strikerPosition: strikerPos,
                aimAngle: aimAngle,
                power: power,
                targetCoin: targetCoin,
                targetPocket: pocket.id,
                shotType: .direct,
                strikerPath: strikerPath,
                coinPath: coinPath
            ))
        }
        
        return shots
    }
    
    // MARK: - Single Rebound Shots
    
    /// Generate single-rebound shot candidates: striker → cushion → coin → pocket.
    private func generateSingleReboundShots(
        targetCoin: Coin,
        pocket: Pocket,
        strikerPositions: [CGPoint],
        allCoins: [Coin]
    ) -> [CandidateShot] {
        var shots: [CandidateShot] = []
        let halfBoard = PhysicsConstants.halfBoard
        
        // For each of the 4 cushions, calculate the rebound point
        let cushions: [(normal: CGVector, wallValue: CGFloat, axis: Axis)] = [
            (CGVector(dx: 0, dy:  1), -halfBoard, .horizontal),  // Top wall
            (CGVector(dx: 0, dy: -1),  halfBoard, .horizontal),  // Bottom wall
            (CGVector(dx:  1, dy: 0), -halfBoard, .vertical),    // Left wall
            (CGVector(dx: -1, dy: 0),  halfBoard, .vertical)     // Right wall
        ]
        
        let coinPos = targetCoin.position
        let pocketPos = pocket.positionMM
        
        // Direction from coin to pocket
        let coinToPocket = (pocketPos - coinPos).normalized
        let contactOffset = coinToPocket * -(targetCoin.physicalRadius + CGFloat(BoardConfig.strikerRadius))
        let aimPoint = coinPos + contactOffset
        
        for cushion in cushions {
            // Mirror the aim point across the cushion to find the virtual target
            let mirroredAimPoint: CGPoint
            
            switch cushion.axis {
            case .horizontal:
                mirroredAimPoint = CGPoint(
                    x: aimPoint.x,
                    y: 2 * cushion.wallValue - aimPoint.y
                )
            case .vertical:
                mirroredAimPoint = CGPoint(
                    x: 2 * cushion.wallValue - aimPoint.x,
                    y: aimPoint.y
                )
            }
            
            for strikerPos in strikerPositions {
                // The striker aims at the mirrored point; the cushion creates the rebound
                let strikerToMirror = mirroredAimPoint - strikerPos
                let aimAngle = strikerToMirror.angle
                
                // Calculate the actual rebound point on the cushion
                let reboundPoint: CGPoint
                switch cushion.axis {
                case .horizontal:
                    let t = (cushion.wallValue - strikerPos.y) / (mirroredAimPoint.y - strikerPos.y)
                    guard t > 0 && t < 1 else { continue }
                    reboundPoint = CGPoint(
                        x: strikerPos.x + t * (mirroredAimPoint.x - strikerPos.x),
                        y: cushion.wallValue
                    )
                case .vertical:
                    let t = (cushion.wallValue - strikerPos.x) / (mirroredAimPoint.x - strikerPos.x)
                    guard t > 0 && t < 1 else { continue }
                    reboundPoint = CGPoint(
                        x: cushion.wallValue,
                        y: strikerPos.y + t * (mirroredAimPoint.y - strikerPos.y)
                    )
                }
                
                // Check if rebound point is within board bounds
                guard abs(reboundPoint.x) <= halfBoard && abs(reboundPoint.y) <= halfBoard else {
                    continue
                }
                
                let totalDistance = strikerPos.distance(to: reboundPoint) + reboundPoint.distance(to: aimPoint)
                let power = estimatePower(
                    strikerToContact: totalDistance,
                    coinToPocket: coinPos.distance(to: pocketPos),
                    rebounds: 1
                )
                
                let strikerPath = [strikerPos, reboundPoint, aimPoint]
                let coinPath = [coinPos, pocketPos]
                
                shots.append(CandidateShot(
                    strikerPosition: strikerPos,
                    aimAngle: aimAngle,
                    power: power,
                    targetCoin: targetCoin,
                    targetPocket: pocket.id,
                    shotType: .singleRebound,
                    strikerPath: strikerPath,
                    coinPath: coinPath
                ))
            }
        }
        
        return shots
    }
    
    // MARK: - Helpers
    
    private enum Axis {
        case horizontal, vertical
    }
    
    /// Check if there's a clear line of sight between two points, considering coin radii.
    private func checkLineOfSight(
        from start: CGPoint,
        to end: CGPoint,
        excludingCoinID: String,
        strikerRadius: CGFloat,
        allCoins: [Coin]
    ) -> Bool {
        let direction = end - start
        let length = direction.magnitude
        guard length > 0 else { return true }
        
        let dx = direction.x / length
        let dy = direction.y / length
        
        for coin in allCoins {
            guard coin.id != excludingCoinID && coin.isInPlay && !coin.isStriker else {
                continue
            }
            
            // Point-to-line-segment distance
            let toObj = coin.position - start
            let proj = toObj.x * dx + toObj.y * dy
            
            // Only check objects between start and end
            guard proj > 0 && proj < length else { continue }
            
            // Perpendicular distance
            let perpX = toObj.x - proj * dx
            let perpY = toObj.y - proj * dy
            let perpDist = sqrt(perpX * perpX + perpY * perpY)
            
            // Clearance needed: striker radius + blocking coin radius
            let clearance = strikerRadius + coin.physicalRadius
            
            if perpDist < clearance {
                return false
            }
        }
        
        return true
    }
    
    /// Estimate the power (velocity magnitude) needed for a shot based on distances.
    private func estimatePower(
        strikerToContact: CGFloat,
        coinToPocket: CGFloat,
        rebounds: Int = 0
    ) -> CGFloat {
        // Basic power estimation:
        // Account for friction losses and rebound energy losses
        let totalDistance = strikerToContact + coinToPocket
        let frictionLoss = PhysicsConstants.surfaceFriction * PhysicsConstants.gravity
        
        // Energy needed = 0.5 * m * v² must overcome friction over total distance
        // v = sqrt(2 * μ * g * d) is minimum velocity for the object to travel distance d
        let minVelocity = sqrt(2.0 * frictionLoss * totalDistance)
        
        // Add extra for rebound energy loss
        let reboundMultiplier: CGFloat = 1.0 + CGFloat(rebounds) * (1.0 - PhysicsConstants.coinCushionRestitution)
        
        // Add safety margin (1.5x) to account for collision energy transfer
        let estimatedPower = minVelocity * reboundMultiplier * 1.5
        
        // Clamp to valid range
        return min(max(estimatedPower, PhysicsConstants.minLaunchVelocity), PhysicsConstants.maxLaunchVelocity)
    }
}
