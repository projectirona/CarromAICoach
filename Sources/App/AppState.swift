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
    
    /// The current live AR state (corners + recommendation).
    public var liveARState: ARState?
    
    /// Error message if analysis fails.
    public var errorMessage: String?
    
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
    
    /// Advance to the next turn while in AR mode.
    public func advanceTurn() {
        matchState?.advanceTurn()
        if let match = matchState {
            matchStore.save(match)
        }
        liveARState = nil
        Log.app.info("Advanced to turn \(self.matchState?.currentTurn ?? 0)")
    }
    
    /// Start a completely new match.
    public func newMatch() {
        matchState = nil
        playerColor = nil
        liveARState = nil
        errorMessage = nil
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
        
        errorMessage = nil
        
        let arState = await recommendationEngine.analyze(
            image: image,
            matchState: matchState
        )
        
        if let arState = arState {
            self.liveARState = arState
            self.matchState?.recordRecommendation(arState.recommendation)
            if let match = self.matchState {
                matchStore.save(match)
            }
        } else {
            // Keep the previous arState if we briefly lose tracking,
            // or we could fade it out after a timeout.
        }
    }
}
