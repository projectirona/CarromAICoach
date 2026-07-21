import Foundation
import SwiftUI
import Combine

// MARK: - App State
/// Global application state manager using @Observable macro.
/// Coordinates between all modules and drives the UI.

@MainActor
@Observable
public final class AppState {
    
    // MARK: - Navigation
    
    /// Current screen in the app flow.
    public enum Screen {
        case colorSelection
        case scanning
        case result
    }
    
    public var currentScreen: Screen = .colorSelection
    
    // MARK: - Match State
    
    /// Current match state (nil if no match started).
    public var matchState: MatchState?
    
    /// Selected player color.
    public var playerColor: PlayerColor?
    
    // MARK: - Camera State
    
    /// Camera manager instance.
    public let cameraManager = CameraManager()
    
    // MARK: - Analysis State
    
    /// Whether the analysis pipeline is running.
    public var isAnalyzing = false
    
    /// The current recommendation (nil if not yet analyzed).
    public var currentRecommendation: Recommendation?
    
    /// Error message if analysis fails.
    public var errorMessage: String?
    
    /// The captured board image for overlay display.
    public var capturedImage: UIImage?
    
    // MARK: - Dependencies
    
    private let recommendationEngine: RecommendationEngine
    private let matchStore: MatchStore
    
    // MARK: - Initialization
    
    public init(
        recommendationEngine: RecommendationEngine = RecommendationEngine(),
        matchStore: MatchStore = MatchStore()
    ) {
        self.recommendationEngine = recommendationEngine
        self.matchStore = matchStore
        
        setupCameraCallback()
    }
    
    // MARK: - Camera Callback
    
    private func setupCameraCallback() {
        cameraManager.onFrameCaptured = { [weak self] image in
            Task { @MainActor in
                self?.capturedImage = image
                await self?.runAnalysis(on: image)
            }
        }
    }
    
    // MARK: - User Actions
    
    /// Select player color and start a new match.
    public func selectColor(_ color: PlayerColor) {
        playerColor = color
        matchState = matchStore.startNewMatch(playerColor: color)
        currentScreen = .scanning
        cameraManager.startSession()
        
        Log.app.info("Color selected: \(color.rawValue)")
    }
    
    /// Start a new scan (after viewing recommendation).
    public func scanAgain() {
        currentRecommendation = nil
        errorMessage = nil
        capturedImage = nil
        currentScreen = .scanning
        cameraManager.resetCapture()
        cameraManager.startSession()
        
        // Advance turn
        matchState?.advanceTurn()
        if let match = matchState {
            matchStore.save(match)
        }
        
        Log.app.info("Scanning again for turn \(self.matchState?.currentTurn ?? 0)")
    }
    
    /// Start a completely new match.
    public func newMatch() {
        matchState = nil
        playerColor = nil
        currentRecommendation = nil
        errorMessage = nil
        capturedImage = nil
        currentScreen = .colorSelection
        cameraManager.stopSession()
        cameraManager.resetCapture()
        
        Log.app.info("New match started")
    }
    
    // MARK: - Analysis Pipeline
    
    /// Run the full analysis pipeline on a captured image.
    private func runAnalysis(on image: UIImage) async {
        guard let matchState = matchState else {
            errorMessage = "No active match"
            return
        }
        
        isAnalyzing = true
        errorMessage = nil
        cameraManager.stopSession()
        
        Log.app.info("Running analysis pipeline...")
        
        let recommendation = await recommendationEngine.analyze(
            image: image,
            matchState: matchState
        )
        
        isAnalyzing = false
        
        if let recommendation = recommendation {
            currentRecommendation = recommendation
            self.matchState?.recordRecommendation(recommendation)
            if let match = self.matchState {
                matchStore.save(match)
            }
            currentScreen = .result
        } else {
            errorMessage = "Could not analyze the board. Please try again."
            cameraManager.resetCapture()
            cameraManager.startSession()
        }
    }
}
