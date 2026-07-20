import Foundation
import UIKit
import Vision
import CoreML

// MARK: - Coin Detector
/// Detects carrom coins (black, white, queen, striker) in a perspective-corrected board image.
/// Uses Core ML object detection model with Vision framework integration.
///
/// NOTE: This implementation includes a mock detector for development/testing
/// until a trained Core ML model is available.

public final class CoinDetector: @unchecked Sendable {
    
    // MARK: - Detection Mode
    
    public enum DetectionMode: Sendable {
        /// Use the Core ML model for real detection.
        case coreML
        /// Use mock detections for testing.
        case mock
    }
    
    // MARK: - Properties
    
    private let mode: DetectionMode
    private var mlModel: VNCoreMLModel?
    
    // MARK: - Initialization
    
    public init(mode: DetectionMode = .mock) {
        self.mode = mode
        
        if mode == .coreML {
            loadModel()
        }
    }
    
    private func loadModel() {
        // TODO: Load trained CoinDetector.mlmodel
        // guard let modelURL = Bundle.main.url(forResource: "CoinDetector", withExtension: "mlmodelc"),
        //       let compiledModel = try? MLModel(contentsOf: modelURL),
        //       let vnModel = try? VNCoreMLModel(for: compiledModel) else {
        //     Log.coinDetection.error("Failed to load Core ML model, falling back to mock")
        //     return
        // }
        // self.mlModel = vnModel
        
        Log.coinDetection.warning("Core ML model not available, using mock detector")
    }
    
    // MARK: - Detection
    
    /// Detect all coins in the perspective-corrected board image.
    ///
    /// - Parameter image: Top-down perspective-corrected board image.
    /// - Returns: Array of detected coins with positions and types.
    public func detectCoins(in image: UIImage) async -> [Coin] {
        switch mode {
        case .coreML:
            return await detectWithCoreML(image)
        case .mock:
            return generateMockDetections(imageSize: image.size)
        }
    }
    
    // MARK: - Core ML Detection
    
    private func detectWithCoreML(_ image: UIImage) async -> [Coin] {
        guard let model = mlModel, let cgImage = image.cgImage else {
            Log.coinDetection.warning("Core ML not available, falling back to mock")
            return generateMockDetections(imageSize: image.size)
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    Log.coinDetection.error("Core ML detection failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let coins = Self.processDetections(results, imageSize: image.size)
                Log.coinDetection.info("Detected \(coins.count) coins via Core ML")
                continuation.resume(returning: coins)
            }
            
            request.imageCropAndScaleOption = .scaleFill
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                Log.coinDetection.error("Vision request failed: \(error.localizedDescription)")
                continuation.resume(returning: [])
            }
        }
    }
    
    /// Process VNRecognizedObjectObservation results into Coin models.
    private static func processDetections(
        _ observations: [VNRecognizedObjectObservation],
        imageSize: CGSize
    ) -> [Coin] {
        var coins: [Coin] = []
        var blackIndex = 0
        var whiteIndex = 0
        
        for observation in observations {
            guard observation.confidence >= AppConfig.coinDetectionConfidenceThreshold else {
                continue
            }
            
            // Get the top classification label
            guard let topLabel = observation.labels.first else { continue }
            
            let detectionType: DetectionType
            switch topLabel.identifier.lowercased() {
            case "black":  detectionType = .blackCoin
            case "white":  detectionType = .whiteCoin
            case "queen":  detectionType = .queen
            case "striker": detectionType = .striker
            default: continue
            }
            
            // Convert bounding box center to board coordinates
            let bbox = observation.boundingBox
            let centerX = (bbox.midX - 0.5) * CGFloat(BoardConfig.playingAreaDimension)
            let centerY = (0.5 - bbox.midY) * CGFloat(BoardConfig.playingAreaDimension)
            let position = CGPoint(x: centerX, y: centerY)
            
            let coin: Coin
            switch detectionType {
            case .blackCoin:
                coin = .black(index: blackIndex, position: position, confidence: observation.confidence)
                blackIndex += 1
            case .whiteCoin:
                coin = .white(index: whiteIndex, position: position, confidence: observation.confidence)
                whiteIndex += 1
            case .queen:
                coin = .queen(position: position, confidence: observation.confidence)
            case .striker:
                coin = .striker(position: position)
            }
            
            coins.append(coin)
        }
        
        // Apply non-maximum suppression
        return applyNMS(coins: coins, iouThreshold: AppConfig.nmsIoUThreshold)
    }
    
    /// Non-maximum suppression to remove duplicate detections.
    private static func applyNMS(coins: [Coin], iouThreshold: Float) -> [Coin] {
        var kept: [Coin] = []
        let sorted = coins.sorted { $0.confidence > $1.confidence }
        
        for coin in sorted {
            let dominated = kept.contains { existing in
                let dist = coin.position.distance(to: existing.position)
                let overlapThreshold = coin.physicalRadius + existing.physicalRadius
                return dist < overlapThreshold * 0.5
            }
            
            if !dominated {
                kept.append(coin)
            }
        }
        
        return kept
    }
    
    // MARK: - Mock Detection
    
    /// Generate realistic mock coin positions for testing.
    /// Places coins in a typical mid-game configuration.
    private func generateMockDetections(imageSize: CGSize) -> [Coin] {
        var coins: [Coin] = []
        let halfArea = BoardConfig.halfPlayingArea
        
        // Place some black coins in realistic positions
        let blackPositions: [(Double, Double)] = [
            (-150, -120), (80, -200), (200, 50),
            (-100, 180), (0, -50), (-250, -80),
            (150, 150)
        ]
        
        for (i, pos) in blackPositions.enumerated() {
            coins.append(.black(
                index: i,
                position: CGPoint(x: pos.0, y: pos.1),
                confidence: 0.95
            ))
        }
        
        // Place some white coins
        let whitePositions: [(Double, Double)] = [
            (100, -150), (-200, -50), (50, 100),
            (-80, -250), (250, -100), (-150, 200),
            (0, 250)
        ]
        
        for (i, pos) in whitePositions.enumerated() {
            coins.append(.white(
                index: i,
                position: CGPoint(x: pos.0, y: pos.1),
                confidence: 0.93
            ))
        }
        
        // Place queen at center
        coins.append(.queen(
            position: CGPoint(x: 20, y: -10),
            confidence: 0.97
        ))
        
        Log.coinDetection.info("Generated \(coins.count) mock coin detections")
        return coins
    }
}
